{#- Data Vault 2.0 hashing. MD5 over trimmed, upper-cased values joined by '||'.
    NULLs become '^^' so (A, NULL) and (NULL, A) never collide. -#}

{% macro hash_key(columns) -%}
    {%- if columns is string -%}{%- set columns = [columns] -%}{%- endif -%}
    md5(concat_ws('||'
    {%- for col in columns -%}
        , coalesce(upper(trim(cast({{ col }} as varchar))), '^^')
    {%- endfor -%}
    ))
{%- endmacro %}

{% macro hash_diff(columns) -%}
    md5(concat_ws('||'
    {%- for col in columns -%}
        , coalesce(trim(cast({{ col }} as varchar)), '^^')
    {%- endfor -%}
    ))
{%- endmacro %}