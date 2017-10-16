#!jinja|yaml

{%- from 'spamassassin/defaults.yaml' import rawmap with context %}
{%- set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('spamassassin:lookup')) %}

include:
  - spamassassin

pyzor:
  pkg:
    - installed

pyzor_dir:
  file:
    - directory
    - name: {{ datamap.config.pyzor_dir.path }}
    - user: {{ datamap.pyzor.user.name|default(datamap.user.name) }}
    - group: {{ datamap.pyzor.group.name|default(datamap.group.name) }}
    - mode: 755

{%- set pyzor_cmds = [
  '/usr/bin/pyzor -d --homedir=' ~  datamap.config.pyzor_dir.path ~ ' discover'
  ]
%}

sa_pyzor_init:
  cmd:
    - run
    - name: {{ pyzor_cmds|join(' ') }}
    - user: {{ datamap.pyzor.user.name|default(datamap.user.name) }}
    - unless: test -e {{ datamap.config.pyzor_dir.path }}/servers
    - require:
      - file: pyzor_dir
    - require_in:
      - service: spamassassin
