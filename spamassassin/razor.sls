#!jinja|yaml

{%- from 'spamassassin/defaults.yaml' import rawmap with context %}
{%- set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('spamassassin:lookup')) %}

include:
  - spamassassin

razor:
  pkg:
    - installed

razor_dir:
  file:
    - directory
    - name: {{ datamap.config.razor_dir.path }}
    - user: {{ datamap.razor.user.name|default(datamap.user.name) }}
    - group: {{ datamap.razor.group.name|default(datamap.group.name) }}
    - mode: 755

{%- set razor_cmds = [
  '/usr/bin/razor-admin -d -home=' ~  datamap.config.razor_dir.path ~ ' -register &&',
  '/usr/bin/razor-admin -d -home=' ~  datamap.config.razor_dir.path ~ ' -create &&',
  '/usr/bin/razor-admin -d -home=' ~  datamap.config.razor_dir.path ~ ' -discover'
  ]
%}

sa_razor_init:
  cmd:
    - run
    - name: {{ razor_cmds|join(' ') }}
    - user: {{ datamap.razor.user.name|default(datamap.user.name) }}
    - unless: test -e {{ datamap.config.razor_dir.path }}/identity
    - require:
      - file: razor_dir
    - require_in:
      - service: spamassassin

{%- set f = datamap.config.razor_agent %}
sa_config_razor_agent:
  file:
    - managed
    - name: {{ f.path }}
    - source: {{ f.template_path|default('salt://spamassassin/files/config/razor-agent.conf') }}
    - mode: {{ f.mode|default(644) }}
    - user: {{ f.user|default(datamap.user.name) }}
    - group: {{ f.group|default(datamap.group.name) }}
    - template: jinja
    - require:
      - cmd: sa_razor_init
    - watch_in:
      - service: spamassassin
