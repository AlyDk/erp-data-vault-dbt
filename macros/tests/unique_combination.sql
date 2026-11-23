{#- Generic test: the combination of the given columns must be unique.
    Used for satellites, where a key may have many versions but only one per load. -#}
{% test unique_combination(model, columns) %}
select {{ columns | join(', ') }}, count(*) as n
from {{ model }}
group by {{ columns | join(', ') }}
having count(*) > 1
{% endtest %}
