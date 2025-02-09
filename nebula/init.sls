###
# nebula
###

{%- from "nebula/map.jinja" import nebula with context %}
{% if nebula.enabled %}

include:
  - nebula.install

/etc/nebula/ca.crt:
  file.managed:
    - source: salt://nebula/cert/ca-ffmuc.crt
    - require:
        - file: /etc/nebula/config.yml
        - file: /etc/nebula/{{ grains['id'] }}.crt

/etc/nebula/{{ grains['id'] }}.crt:
  file.managed:
    - source: salt://nebula/cert/{{ grains['id'] }}.crt
    - makedirs: True
    - user: root
    - group: root
    - mode: 644

/etc/nebula/{{ grains['id'] }}.key:
  file.managed:
    - source: salt://nebula/cert/{{ grains['id'] }}.key
    - makedirs: True
    - user: root
    - group: root
    - mode: 640

{% if nebula.loophole.enabled %}
generate_ssh_host_ed25519_key:
  cmd.run:
    - name: ssh-keygen -t ed25519 -q -N "" -f /etc/nebula/ssh_host_ed25519_key
    - unless: test -f /etc/nebula/ssh_host_ed25519_key
    - require_in:
      - file: /etc/nebula/config.yml
{% endif %}

/etc/nebula/config.yml:
  file.managed:
    - source:
        - salt://nebula/files/{{ grains['id'] }}-config.yml.jinja
        - salt://nebula/files/config.yml.jinja
    - makedirs: True
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
        - file: /etc/nebula/{{ grains['id'] }}.crt

systemd-reload-nebula:
  cmd.run:
   - name: systemctl --system daemon-reload
   - onchanges:  
     - file: nebula-service-file

nebula-service-file:
  file.managed:
    - source: salt://nebula/files/nebula.service
    - name: /etc/systemd/system/nebula.service
    - require:
        - file: /etc/nebula/{{ grains['id'] }}.crt

nebula-service:
  service.running:
    - enable: True
    - running: True
    - reload: True
    - name: nebula
    - require:
        - file: nebula-service-file
        - file: /etc/nebula/config.yml
        - file: /etc/nebula/{{ grains['id'] }}.crt
        - file: /etc/nebula/{{ grains['id'] }}.key
        - file: nebula-binary
    - watch:
        - file: /etc/nebula/config.yml

{% else %}
{# remove old config to allow migration to new file destination #}
/etc/nebula/ca.crt:
  file.absent
/etc/nebula/{{ grains['id'] }}.crt:
  file.absent
/etc/nebula/{{ grains['id'] }}.key:
  file.absent
/etc/nebula/config.yml:
  file.absent
/etc/systemd/system/nebula.service:
  file.absent

{% endif %}