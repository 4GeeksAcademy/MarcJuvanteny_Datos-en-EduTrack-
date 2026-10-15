-- =====================================================
-- EduTrack v2 — queries.sql
-- =====================================================

-- -----------------------------------------------------
-- 0. Verificación de la importación
-- -----------------------------------------------------
SELECT * FROM enrollments LIMIT 5;
SELECT * FROM students    LIMIT 5;
SELECT * FROM courses     LIMIT 5;


-- -----------------------------------------------------
-- 1. INNER JOIN — Todas las inscripciones con el nombre completo
--    del estudiante, el título del curso y su % de completado
-- -----------------------------------------------------
SELECT
    e.id                    AS enrollment_id,
    s.name                  AS student_name,
    c.title                 AS course_title,
    e.completion_percentage
FROM enrollments e
INNER JOIN students s ON s.id = e.student_id
INNER JOIN courses  c ON c.id = e.course_id
ORDER BY e.id;
-- Resultado: 16 filas (Giulia Romano y "Email Campaigns" no aparecen
-- porque no tienen inscripciones: INNER JOIN solo devuelve coincidencias).


-- -----------------------------------------------------
-- 2. INNER JOIN — Nombre y email de los estudiantes que han aprobado
--    al menos un curso, junto con el título del curso aprobado
-- -----------------------------------------------------
SELECT
    s.name   AS student_name,
    s.email,
    c.title  AS course_title
FROM enrollments e
INNER JOIN students s ON s.id = e.student_id
INNER JOIN courses  c ON c.id = e.course_id
WHERE e.passed = TRUE
ORDER BY s.name, c.title;
-- Resultado: 6 filas, 4 estudiantes distintos.


-- -----------------------------------------------------
-- 3. INNER JOIN — % de completado medio por instructor,
--    ordenado de mayor a menor
-- -----------------------------------------------------
SELECT
    c.instructor_name,
    ROUND(AVG(e.completion_percentage), 2) AS avg_completion,
    COUNT(e.id)                            AS total_enrollments
FROM enrollments e
INNER JOIN courses c ON c.id = e.course_id
GROUP BY c.instructor_name
ORDER BY avg_completion DESC;
-- Resultado: 4 filas. "Pending assignment" no es un instructor real
-- (curso UI/UX Fundamentals sin asignar); se puede excluir con
-- WHERE c.instructor_name <> 'Pending assignment'.


-- =====================================================
-- LEFT JOIN — Detección de datos faltantes
-- =====================================================

-- 4. Estudiantes sin ninguna inscripción
--    (LEFT JOIN conserva todos los estudiantes; los que no casan
--     con enrollments quedan con e.id = NULL)
SELECT
    s.id,
    s.name,
    s.email,
    s.signup_date
FROM students s
LEFT JOIN enrollments e ON e.student_id = s.id
WHERE e.id IS NULL;
-- Resultado: 1 fila → Giulia Romano


-- 5. Cursos sin ninguna inscripción
SELECT
    c.id,
    c.title,
    c.category,
    c.instructor_name
FROM courses c
LEFT JOIN enrollments e ON e.course_id = c.id
WHERE e.id IS NULL;
-- Resultado: 1 fila → Email Campaigns


-- =====================================================
-- Agregación entre tablas
-- =====================================================

-- 6. Número de cursos por estudiante (solo los inscritos en más de uno)
SELECT
    s.name                       AS student_name,
    COUNT(DISTINCT e.course_id)  AS total_courses
FROM students s
INNER JOIN enrollments e ON e.student_id = s.id
GROUP BY s.id, s.name
HAVING COUNT(DISTINCT e.course_id) > 1
ORDER BY total_courses DESC, student_name;
-- Resultado: 7 filas


-- 7. Ingresos totales por categoría usando courses.monthly_fee
--    (cada inscripción aporta el precio actual del curso)
SELECT
    c.category,
    SUM(c.monthly_fee)  AS total_revenue,
    COUNT(e.id)         AS total_enrollments
FROM courses c
INNER JOIN enrollments e ON e.course_id = c.id
GROUP BY c.category
ORDER BY total_revenue DESC;
-- Resultado: 4 filas


-- 8. Cada instructor con el número de estudiantes inscritos en sus cursos
--    (LEFT JOIN para que aparezcan también instructores con 0 alumnos;
--     DISTINCT para no contar dos veces a un alumno en dos cursos del mismo instructor)
SELECT
    c.instructor_name,
    COUNT(DISTINCT e.student_id)  AS total_students,
    COUNT(e.id)                   AS total_enrollments
FROM courses c
LEFT JOIN enrollments e ON e.course_id = c.id
GROUP BY c.instructor_name
ORDER BY total_students DESC, c.instructor_name;
-- Resultado: 4 filas


-- =====================================================
-- Integridad de datos (registros huérfanos)
-- =====================================================

-- 9. Inscripciones cuyo student_id no existe en students
SELECT
    e.id         AS enrollment_id,
    e.student_id,
    e.course_id
FROM enrollments e
LEFT JOIN students s ON s.id = e.student_id
WHERE s.id IS NULL;
-- Resultado: 0 filas


-- 10. Inscripciones cuyo course_id no existe en courses
SELECT
    e.id         AS enrollment_id,
    e.student_id,
    e.course_id
FROM enrollments e
LEFT JOIN courses c ON c.id = e.course_id
WHERE c.id IS NULL;
-- Resultado: 0 filas