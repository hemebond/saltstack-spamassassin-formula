#!jinja|yaml

{%- from 'spamassassin/defaults.yaml' import rawmap with context %}
{%- set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('spamassassin:lookup')) %}

include: {{ datamap.sls_include|default([]) }}
extend: {{ datamap.sls_extend|default({}) }}

spamassassin:
  pkg:
    - installed
    - pkgs: {{ datamap.pkgs }}
    - require: {{ datamap.init_require|default([]) }}
  service:
    - {{ datamap.service.ensure|default('running') }}
    - name: {{ datamap.service.name|default('spamassassin') }}
    - enable: {{ datamap.service.enable|default(True) }}

{%- for i, f in (datamap.config.manage|default({})).items() %}
spamassassin_config_{{ i }}:
  file:
    - managed
    - name: {{ f.path }}
    - source: {{ f.template_path|default('salt://files/spamassassin/' ~ i) }}
    - mode: {{ f.mode|default(644) }}
    - user: {{ f.user|default('root') }}
    - group: {{ f.group|default('root') }}
    - template: jinja
    - watch_in:
      - service: spamassassin
{%- endfor %}

{%- for f in datamap.configs_absent|default([]) %}
spamassassin_config_absent_{{ f }}:
  file:
    - absent
    - name: {{ f }}
    - watch_in:
      - service: spamassassin
{%- endfor %}
