def test_database_connection(db_connection):
    assert db_connection.closed is False
    with db_connection.cursor() as cur:
        cur.execute("SELECT 1")
        result = cur.fetchone()
    assert result == (1,), f"Ожидали (1,), получили {result}"


def test_simple_select_now(db_connection):
    with db_connection.cursor() as cur:
        cur.execute("SELECT now()")
        row = cur.fetchone()
    assert row is not None
    print(f"\nВремя сервера БД: {row[0]}")
