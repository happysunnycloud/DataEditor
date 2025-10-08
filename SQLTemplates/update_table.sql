PRAGMA foreign_keys = 0;

update
    :table_name
set
    :field_list
where
    :where_section
;

PRAGMA foreign_keys = 1;