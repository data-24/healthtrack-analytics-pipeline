{% macro calculate_los(admit_date_col, discharge_date_col) %}
    DATEDIFF('day', {{ admit_date_col }}, {{ discharge_date_col }})
{% endmacro %}