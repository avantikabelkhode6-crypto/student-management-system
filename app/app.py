
from flask import Flask, render_template, request, redirect, url_for, flash
import sqlite3

app = Flask(__name__)
app.secret_key = "student-management-local-secret"


def get_db_connection():
    conn = sqlite3.connect("students.db")
    conn.row_factory = sqlite3.Row
    return conn


def create_table():
    conn = get_db_connection()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            student_id TEXT NOT NULL,
            course TEXT NOT NULL
        )
    """)
    conn.commit()
    conn.close()


@app.route("/")
def home():
    search = request.args.get("search", "").strip()

    conn = get_db_connection()

    if search:
        students = conn.execute("""
            SELECT * FROM students
            WHERE name LIKE ? OR student_id LIKE ? OR course LIKE ?
            ORDER BY id DESC
        """, (f"%{search}%", f"%{search}%", f"%{search}%")).fetchall()
    else:
        students = conn.execute(
            "SELECT * FROM students ORDER BY id DESC"
        ).fetchall()

    total_students = conn.execute(
        "SELECT COUNT(*) FROM students"
    ).fetchone()[0]

    total_courses = conn.execute(
        "SELECT COUNT(DISTINCT course) FROM students"
    ).fetchone()[0]

    courses = conn.execute(
        "SELECT DISTINCT course FROM students ORDER BY course"
    ).fetchall()

    conn.close()

    return render_template(
        "index.html",
        students=students,
        total_students=total_students,
        total_courses=total_courses,
        courses=courses,
        search=search
    )


@app.route("/add", methods=["POST"])
def add_student():
    name = request.form.get("name", "").strip()
    student_id = request.form.get("student_id", "").strip()
    course = request.form.get("course", "").strip()

    if not name or not student_id or not course:
        flash("Please fill in all student details.", "error")
        return redirect(url_for("home"))

    conn = get_db_connection()

    try:
        conn.execute("""
            INSERT INTO students (name, student_id, course)
            VALUES (?, ?, ?)
        """, (name, student_id, course))
        conn.commit()
        flash("Student added successfully!", "success")
    except sqlite3.IntegrityError:
        flash("Unable to add student.", "error")
    finally:
        conn.close()

    return redirect(url_for("home"))


@app.route("/update/<int:id>", methods=["POST"])
def update_student(id):
    name = request.form.get("name", "").strip()
    student_id = request.form.get("student_id", "").strip()
    course = request.form.get("course", "").strip()

    if not name or not student_id or not course:
        flash("All fields are required.", "error")
        return redirect(url_for("home"))

    conn = get_db_connection()
    conn.execute("""
        UPDATE students
        SET name=?, student_id=?, course=?
        WHERE id=?
    """, (name, student_id, course, id))
    conn.commit()
    conn.close()

    flash("Student details updated successfully!", "success")
    return redirect(url_for("home"))


@app.route("/delete/<int:id>", methods=["POST"])
def delete_student(id):
    conn = get_db_connection()
    conn.execute("DELETE FROM students WHERE id=?", (id,))
    conn.commit()
    conn.close()

    flash("Student deleted successfully!", "success")
    return redirect(url_for("home"))


@app.errorhandler(404)
def page_not_found(error):
    return render_template("404.html"), 404


@app.errorhandler(500)
def server_error(error):
    return "Internal Server Error. Please try again later.", 500


if __name__ == "__main__":
    create_table()
    app.run(host="0.0.0.0", port=5000, debug=False)


