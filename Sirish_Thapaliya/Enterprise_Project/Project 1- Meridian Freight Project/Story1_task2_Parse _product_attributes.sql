SELECT * FROM products LIMIT 10;


SET SQL_SAFE_UPDATES = 0;

UPDATE products
SET grade = SUBSTRING_INDEX(SUBSTRING_INDEX(product_name, '-', 2), '-', -1),
    pack_size = SUBSTRING_INDEX(SUBSTRING_INDEX(product_name, '-', 3), '-', -1),
    product_ref_no = SUBSTRING_INDEX(product_name, '-', -1);

SELECT product_name, grade, pack_size, product_ref_no FROM products LIMIT 10;

## check sanity
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN grade IS NULL THEN 1 ELSE 0 END) AS missing_grade,
       SUM(CASE WHEN pack_size IS NULL THEN 1 ELSE 0 END) AS missing_pack_size
FROM products;


