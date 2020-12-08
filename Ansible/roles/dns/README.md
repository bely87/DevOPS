Role Name
=========

Role to add A and PTR records to DNS/IDM server.

Requirements
------------

1. Required ansible v2.4 !!!
2. You have to set 2 variables - 'ipa_user' and 'ipa_pass'

It can be done in main playbook like

      vars_prompt:
      - name: "ipa_user"
        prompt: "username:"
        private: no

      - name: "ipa_pass"
        prompt: "password:"
        private: yes

Role Variables
--------------

ipa_user - used to exchange with IDM api

ipa_pass - also used for IDM requests

Dependencies
------------

Ansible version >=2.4

Example Playbook
----------------

```yaml
- hosts: all
  gather_facts: no

  vars_prompt:
  - name: "ipa_user"
    prompt: "username:"
    private: no

  - name: "ipa_pass"
    prompt: "password:"
    private: yes

  roles:
    - role: dns
      tags: dns
```



License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
