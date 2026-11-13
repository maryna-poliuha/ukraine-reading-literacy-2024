
-- 1. Перевірка якості даних після імпорту CSV у SQLite.
-- Рахує загальну кількість учнів, кількість унікальних ID
-- та пропуски (NULL) у показниках LOVE, CONF і ANXI.
-- Порівнюємо результати з перевірками в Google Sheets.
-- Важливо: COUNT не вважає порожній текст ('') пропуском.

SELECT
    COUNT(*) AS total_students,
    COUNT(DISTINCT "BARCODE.x") AS unique_students,
    COUNT(*) - COUNT(LOVE) AS missing_love,
    COUNT(*) - COUNT(CONF) AS missing_conf,
    COUNT(*) - COUNT(ANXI) AS missing_anxi
FROM Student_read;




-- 2.Перевірка пропусків після імпорту CSV у SQLite.
-- Для кожного показника окремо рахуємо:
-- 1. NULL — справді відсутні значення.
-- 2. Порожній текст ('') — можливі некоректно імпортовані пропуски.
-- Запит не змінює дані.

SELECT
    COUNT(*) - COUNT(LOVE) AS null_love,
    SUM(CASE WHEN LOVE = '' THEN 1 ELSE 0 END) AS empty_love,

    COUNT(*) - COUNT(CONF) AS null_conf,
    SUM(CASE WHEN CONF = '' THEN 1 ELSE 0 END) AS empty_conf,

    COUNT(*) - COUNT(ANXI) AS null_anxi,
    SUM(CASE WHEN ANXI = '' THEN 1 ELSE 0 END) AS empty_anxi,

    COUNT(*) - COUNT(SUPP) AS null_supp,
    SUM(CASE WHEN SUPP = '' THEN 1 ELSE 0 END) AS empty_supp,

    COUNT(*) - COUNT(HOME) AS null_home,
    SUM(CASE WHEN HOME = '' THEN 1 ELSE 0 END) AS empty_home,

    COUNT(*) - COUNT(BULL) AS null_bull,
    SUM(CASE WHEN BULL = '' THEN 1 ELSE 0 END) AS empty_bull
FROM Student_read;



-- 3. Заміна порожнього тексту на NULL
-- Після імпорту CSV пропуски збереглися як порожній текст ('').
-- WHERE перевіряє шість перелічених стовпців у кожному рядку.
-- Якщо хоча б один із них містить '', рядок обирається для оновлення.
-- SET перевіряє значення кожного з цих стовпців окремо:
-- порожній текст ('') замінює на NULL, інші значення не змінює.
-- Запит змінює дані в таблиці Student_read.

UPDATE Student_read
SET
    LOVE = NULLIF(LOVE, ''),
    CONF = NULLIF(CONF, ''),
    ANXI = NULLIF(ANXI, ''),
    SUPP = NULLIF(SUPP, ''),
    HOME = NULLIF(HOME, ''),
    BULL = NULLIF(BULL, '')
WHERE
    LOVE = ''
    OR CONF = ''
    OR ANXI = ''
    OR SUPP = ''
    OR HOME = ''
    OR BULL = '';



-- 4. Перевірка результатів очищення даних
-- Перевіряємо, чи правильно спрацював запит №3.
-- COUNT(*) рахує всіх учнів.
-- COUNT(LOVE) рахує учнів, у яких LOVE не є NULL.
-- Різниця показує кількість пропусків у LOVE.
-- Так само перевіряємо решту п'яти показників.
-- Очікуємо: 3602 учні та 133, 205, 156, 149, 154, 168 пропусків.
-- Запит лише перевіряє дані, нічого не змінює.

SELECT
    COUNT(*) AS total_students,
    COUNT(*) - COUNT(LOVE) AS null_love,
    COUNT(*) - COUNT(CONF) AS null_conf,
    COUNT(*) - COUNT(ANXI) AS null_anxi,
    COUNT(*) - COUNT(SUPP) AS null_supp,
    COUNT(*) - COUNT(HOME) AS null_home,
    COUNT(*) - COUNT(BULL) AS null_bull
FROM Student_read;



-- 5. Остаточна перевірка якості основних даних.
-- Перевіряємо стовпці, необхідні для дослідження
-- читацької грамотності, булінгу та підтримки родини.
--
-- COUNT(*) рахує загальну кількість учнів.
--
-- COUNT(*) - COUNT("BARCODE.x") перевіряє пропуски ID учнів.
-- COUNT(*) - COUNT("BARCODE_School") перевіряє пропуски ID шкіл.
--
-- SCORE_100_300 — результат читання за шкалою 100–300.
-- Перевіряємо наявність NULL і значень поза межами 100–300.
--
-- BENCHMARK — рівень читацьких досягнень (1, 2, 3, 4).
-- Перевіряємо пропуски та значення поза цими категоріями.
--
-- W_student — статистична вага учня.
-- Перевіряємо пропуски та ваги, менші або рівні нулю.
-- Ваги потрібні для правильного розрахунку показників.
--
-- BULL — категорія індексу булінгу (1, 2, 3).
-- SUPP — категорія підтримки родини (1, 2, 3).
-- Перевіряємо, чи немає значень поза допустимими категоріями.
-- Відомі пропуски NULL у цих стовпцях уже перевірені
-- в запитах №2 і №4, тому повторно їх не рахуємо.
--
-- CASE WHEN визначає некоректні значення.
-- SUM підраховує їхню кількість.
--
-- Очікуємо 3602 учні та нулі в усіх інших стовпцях.
-- Запит лише перевіряє дані, нічого не змінює.

SELECT
    COUNT(*) AS total_students,

    COUNT(*) - COUNT("BARCODE.x") AS null_student_id,
    COUNT(*) - COUNT("BARCODE_School") AS null_school_id,

    COUNT(*) - COUNT(SCORE_100_300) AS null_score,
    SUM(CASE WHEN SCORE_100_300 NOT BETWEEN 100 AND 300
        THEN 1 ELSE 0 END) AS invalid_score,

    COUNT(*) - COUNT(BENCHMARK) AS null_benchmark,
    SUM(CASE WHEN BENCHMARK NOT IN (1, 2, 3, 4)
        THEN 1 ELSE 0 END) AS invalid_benchmark,

    COUNT(*) - COUNT(W_student) AS null_weight,
    SUM(CASE WHEN W_student <= 0
        THEN 1 ELSE 0 END) AS invalid_weight,

    SUM(CASE WHEN BULL IS NOT NULL
             AND BULL NOT IN (1, 2, 3)
        THEN 1 ELSE 0 END) AS invalid_bull,

    SUM(CASE WHEN SUPP IS NOT NULL
             AND SUPP NOT IN (1, 2, 3)
        THEN 1 ELSE 0 END) AS invalid_supp

FROM Student_read;



-- 6. Загальні результати читацької грамотності четвертокласників.
-- Визначаємо кількість учнів, середній бал читання
-- та частку дітей, які не досягли базового рівня.
--
-- COUNT(*) рахує загальну кількість учнів у вибірці.
--
-- SCORE_100_300 — результат читання за шкалою 100–300.
-- W_student — статистична вага учня.
--
-- SUM(SCORE_100_300 * W_student) / SUM(W_student)
-- розраховує зважений середній бал читання.
-- Враховує статистичну вагу кожного учня,
-- щоб результат краще відображав досліджувану сукупність.
--
-- BENCHMARK = 1 — передбазовий рівень читання.
-- CASE WHEN визначає учнів із передбазовим рівнем.
-- SUM підсумовує їхні статистичні ваги.
-- Ділимо на суму ваг усіх учнів і множимо на 100,
-- щоб отримати зважену частку у відсотках.
--
-- ROUND(..., 2) округлює результати до двох знаків.
--
-- Запит показує загальну ситуацію з читанням
-- без поділу за булінгом і підтримкою родини.
-- Ці результати використаємо для подальших порівнянь.
-- Запит лише аналізує дані, нічого не змінює.

SELECT
    COUNT(*) AS total_students,

    ROUND(
        SUM(SCORE_100_300 * W_student) / SUM(W_student),
        2
    ) AS weighted_avg_score,  -- зважений середній бал читання всіх учнів

    ROUND(
        100.0 * SUM(
            CASE WHEN BENCHMARK = 1
                THEN W_student ELSE 0 END
        ) / SUM(W_student),
        2
    ) AS below_basic_pct  -- зважений відсоток учнів, які мають найнижчий, 
    -- тобто передбазовий, рівень читацьких досягнень (BENCHMARK = 1).

FROM Student_read;



-- 7. Розподіл рівнів читання та перевірка пропусків.
--
-- BENCHMARK — рівень читання:
-- 1 — передбазовий, 2 — базовий,
-- 3 — середній, 4 — високий.
--
-- students_count — фактична кількість учнів кожного рівня.
--
-- weighted_pct — зважена частка учнів кожного рівня (%).
-- Суму ваг учнів рівня ділимо на суму ваг усіх учнів.
-- Вкладений SELECT обчислює загальну суму ваг.
--
-- missing_anxi — кількість учнів без даних про тривожність.
-- missing_supp — кількість учнів без даних про підтримку.
--
-- missing_either — кількість учнів, у яких відсутній
-- ANXI або SUPP (кожного учня рахуємо один раз).
--
-- missing_either_pct — частка таких учнів на кожному
-- рівні читання (%), без статистичних ваг.
--
-- CASE WHEN визначає пропуски, а SUM підраховує їх.
-- Запит не змінює дані.

SELECT
    BENCHMARK,
    COUNT(*) AS students_count,

    ROUND(
        100.0 * SUM(W_student) /
        (SELECT SUM(W_student) FROM Student_read),
        2
    ) AS weighted_pct,

    SUM(CASE WHEN ANXI IS NULL
        THEN 1 ELSE 0 END) AS missing_anxi,

    SUM(CASE WHEN SUPP IS NULL
        THEN 1 ELSE 0 END) AS missing_supp,

    SUM(CASE WHEN ANXI IS NULL OR SUPP IS NULL
        THEN 1 ELSE 0 END) AS missing_either,

    ROUND(
        100.0 * SUM(
            CASE WHEN ANXI IS NULL OR SUPP IS NULL
                THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS missing_either_pct

FROM Student_read
GROUP BY BENCHMARK
ORDER BY BENCHMARK;



-- 8. Навчальна тривожність і читацька грамотність.
-- Порівнюємо результати трьох груп учнів за ANXI.
--
-- ANXI — навчальна тривожність:
-- 1 — низька, 2 — середня, 3 — висока.
--
-- students_count — фактична кількість учнів у групі.
--
-- weighted_avg_score — зважений середній бал читання.
-- Суму балів, помножених на ваги учнів, ділимо
-- на загальну суму ваг відповідної групи.
--
-- below_basic_pct — зважена частка учнів (%),
-- які не досягли базового рівня читання.
-- CASE WHEN BENCHMARK = 1 враховує ваги лише
-- учнів передбазового рівня.
-- Їхню суму ділимо на суму ваг усієї групи.
--
-- Виключаємо 156 учнів із відсутнім ANXI.
-- Запит не змінює дані.

SELECT
    ANXI,
    COUNT(*) AS students_count,

    ROUND(
        SUM(SCORE_100_300 * W_student) / SUM(W_student),
        2
    ) AS weighted_avg_score,

    ROUND(
        100.0 * SUM(
            CASE WHEN BENCHMARK = 1
                THEN W_student ELSE 0 END
        ) / SUM(W_student),
        2
    ) AS below_basic_pct

FROM Student_read
WHERE ANXI IS NOT NULL
GROUP BY ANXI
ORDER BY ANXI;



-- 9. Аналіз підтримки родини та читацької грамотності.
-- Порівнюємо результати читання учнів із низьким,
-- середнім і високим рівнем сімейної підтримки.
-- Мета — визначити, чи відрізняються їхні результати.
--
-- SUPP — рівень підтримки родини:
-- 1 — низький, 2 — середній, 3 — високий.
--
-- students_count — фактична кількість учнів кожної групи.
--
-- weighted_avg_score — зважений середній бал читання.
-- Множимо бал кожного учня на його статистичну вагу,
-- додаємо результати та ділимо на суму ваг групи.
--
-- below_basic_pct — зважений відсоток учнів,
-- які не досягли базового рівня читання.
-- CASE WHEN BENCHMARK = 1 відбирає ваги таких учнів.
-- Ділимо їхню суму на суму ваг групи та множимо на 100.
--
-- WHERE SUPP IS NOT NULL виключає 149 учнів,
-- для яких рівень підтримки родини невідомий.
--
-- Результат — три групи підтримки родини.
-- Запит не змінює дані.

SELECT
    SUPP,
    COUNT(*) AS students_count,

    ROUND(
        SUM(SCORE_100_300 * W_student) / SUM(W_student),
        2
    ) AS weighted_avg_score,

    ROUND(
        100.0 * SUM(
            CASE WHEN BENCHMARK = 1
                THEN W_student ELSE 0 END
        ) / SUM(W_student),
        2
    ) AS below_basic_pct

FROM Student_read
WHERE SUPP IS NOT NULL
GROUP BY SUPP
ORDER BY SUPP;



-- 10. Розподіл учнів за тривожністю та підтримкою родини.
-- Формуємо 9 груп за поєднанням ANXI × SUPP.
--
-- ANXI — тривожність: 1 — низька, 2 — середня,
-- 3 — висока.
-- SUPP — підтримка родини: 1 — низька, 2 — середня,
-- 3 — висока.
--
-- students_count — фактична кількість учнів групи.
--
-- below_basic_count — кількість учнів, які не досягли
-- базового рівня читання (BENCHMARK = 1).
-- CASE WHEN позначає таких учнів одиницею,
-- SUM підраховує їхню кількість.
--
-- Виключаємо записи з відсутнім ANXI або SUPP.
-- Очікуємо 3392 учні у 9 групах.
-- Показники без статистичних ваг.
-- Запит не змінює дані.

SELECT
    ANXI,
    SUPP,
    COUNT(*) AS students_count,

    SUM(
        CASE WHEN BENCHMARK = 1
            THEN 1 ELSE 0 END
    ) AS below_basic_count

FROM Student_read
WHERE ANXI IS NOT NULL
  AND SUPP IS NOT NULL
GROUP BY ANXI, SUPP
ORDER BY ANXI, SUPP;



-- 11. Зважений середній бал у дев'яти групах.
-- Порівнюємо результати читання за поєднаннями
-- навчальної тривожності та підтримки родини.
--
-- ANXI — тривожність:
-- 1 — низька, 2 — середня, 3 — висока.
--
-- SUPP — підтримка родини:
-- 1 — низька, 2 — середня, 3 — висока.
--
-- students_count — фактична кількість учнів у групі.
--
-- weighted_avg_score — зважений середній бал читання.
-- Бал кожного учня множимо на його статистичну вагу,
-- додаємо результати та ділимо на суму ваг групи.
-- Так враховуємо різну представленість учнів
-- у досліджуваній сукупності.
--
-- Виключаємо учнів із відсутнім ANXI або SUPP.
-- Очікуємо 9 груп і загалом 3392 учні.
-- Запит не змінює дані.

SELECT
    ANXI,
    SUPP,
    COUNT(*) AS students_count,

    ROUND(
        SUM(SCORE_100_300 * W_student) / SUM(W_student),
        2
    ) AS weighted_avg_score

FROM Student_read
WHERE ANXI IS NOT NULL
  AND SUPP IS NOT NULL
GROUP BY ANXI, SUPP
ORDER BY ANXI, SUPP;



-- 12. Частка передбазового рівня за ANXI та SUPP.
-- Порівнюємо 9 груп учнів за поєднаннями
-- навчальної тривожності та підтримки родини.
--
-- ANXI — тривожність: 1 — низька,
-- 2 — середня, 3 — висока.
-- SUPP — підтримка: 1 — низька,
-- 2 — середня, 3 — висока.
--
-- students_count — фактична кількість учнів у групі.
--
-- below_basic_count — кількість учнів, які не досягли
-- базового рівня читання (BENCHMARK = 1).
--
-- below_basic_pct — зважена частка таких учнів (%).
-- CASE WHEN враховує статистичні ваги лише учнів
-- із передбазовим рівнем.
-- Суму їхніх ваг ділимо на суму ваг усієї групи
-- та множимо на 100.
--
-- Виключаємо записи з відсутнім ANXI або SUPP.
-- Очікуємо 9 груп із загалом 3392 учнями.
-- Запит не змінює дані.

SELECT
    ANXI,
    SUPP,
    COUNT(*) AS students_count,

    SUM(
        CASE WHEN BENCHMARK = 1
            THEN 1 ELSE 0 END
    ) AS below_basic_count,

    ROUND(
        100.0 * SUM(
            CASE WHEN BENCHMARK = 1
                THEN W_student ELSE 0 END
        ) / SUM(W_student),
        2
    ) AS below_basic_pct

FROM Student_read
WHERE ANXI IS NOT NULL
  AND SUPP IS NOT NULL
GROUP BY ANXI, SUPP
ORDER BY ANXI, SUPP;



-- 13. Підсумкові дані для Tableau.
-- Об'єднуємо головні результати дев'яти груп
-- за тривожністю та підтримкою родини.
--
-- ANXI — тривожність: 1 — низька,
-- 2 — середня, 3 — висока.
-- SUPP — підтримка: 1 — низька,
-- 2 — середня, 3 — висока.
--
-- students_count — фактична кількість учнів групи.
--
-- below_basic_count — кількість учнів, які не досягли
-- базового рівня читання (BENCHMARK = 1).
--
-- weighted_avg_score — зважений середній бал читання.
-- Суму балів, помножених на ваги учнів,
-- ділимо на суму ваг відповідної групи.
--
-- below_basic_pct — зважена частка учнів (%),
-- які не досягли базового рівня читання.
-- CASE WHEN враховує ваги лише таких учнів.
-- Їхню суму ділимо на суму ваг усієї групи.
--
-- Виключаємо записи з відсутнім ANXI або SUPP.
-- Очікуємо 9 рядків із загалом 3392 учнями.
-- Запит не змінює дані.

SELECT
    ANXI,
    SUPP,
    COUNT(*) AS students_count,

    SUM(
        CASE WHEN BENCHMARK = 1
            THEN 1 ELSE 0 END
    ) AS below_basic_count,

    ROUND(
        SUM(SCORE_100_300 * W_student) / SUM(W_student),
        2
    ) AS weighted_avg_score,

    ROUND(
        100.0 * SUM(
            CASE WHEN BENCHMARK = 1
                THEN W_student ELSE 0 END
        ) / SUM(W_student),
        2
    ) AS below_basic_pct

FROM Student_read
WHERE ANXI IS NOT NULL
  AND SUPP IS NOT NULL
GROUP BY ANXI, SUPP
ORDER BY ANXI, SUPP;
