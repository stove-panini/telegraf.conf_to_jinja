telegraf.conf.d to jinja
========================
Now presenting a terrible awk script that works for 81% of the telegraf plugin config files.

This splits up the huge telegraf.conf into separate files for each plugin, generates a jinja template, and creates a vars file for Ansible.
