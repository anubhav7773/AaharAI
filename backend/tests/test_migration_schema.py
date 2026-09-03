from pathlib import Path
import sqlite3


def test_migrations_files_exist_and_contain_guest_fix():
    migrations_dir = Path(__file__).resolve().parents[1] / "migrations"
    m1 = migrations_dir / "001_initial_schema.sql"
    m2 = migrations_dir / "002_fix_profiles_guest_email.sql"

    assert m1.exists()
    assert m2.exists()

    m1_content = m1.read_text(encoding="utf-8")
    assert "email text unique," in m1_content
    assert "nullif(trim(coalesce(new.email, '')), '')" in m1_content

    m2_content = m2.read_text(encoding="utf-8")
    assert "alter column email drop not null" in m2_content
    assert "nullif(trim(coalesce(new.email, '')), '')" in m2_content


def test_unique_null_semantics_for_guest_users():
    """Verify standard SQL uniqueness semantics where NULLs do not conflict,
    validating why nullif(..., '') prevents guest account collisions."""
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()

    cur.execute(
        """
        CREATE TABLE profiles (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE,
            display_name TEXT
        );
        """
    )

    def trigger_emulation(user_id: str, raw_email: str | None, full_name: str | None):
        email_val = None if not raw_email or not raw_email.strip() else raw_email.strip()
        name_val = full_name or "Guest User"
        cur.execute(
            "INSERT INTO profiles (id, email, display_name) VALUES (?, ?, ?)",
            (user_id, email_val, name_val),
        )

    # Guest 1 signs in (no email)
    trigger_emulation("guest-uuid-1", None, None)

    # Guest 2 signs in (empty email)
    trigger_emulation("guest-uuid-2", "", None)

    # Guest 3 signs in (whitespace email)
    trigger_emulation("guest-uuid-3", "   ", None)

    # Authenticated user signs in with email
    trigger_emulation("auth-uuid-1", "user1@example.com", "User One")

    cur.execute("SELECT id, email, display_name FROM profiles ORDER BY id")
    rows = cur.fetchall()
    assert len(rows) == 4

    guest_rows = [r for r in rows if r[1] is None]
    assert len(guest_rows) == 3
    for g in guest_rows:
        assert g[2] == "Guest User"

    conn.close()
