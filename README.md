Backups
=======

These are scripts written to perform various backup-related tasks.


db-backup.py
------------

Backup databases! See source for configuration and usage.

I like to use email for remote backups. It's cheap (a free Gmail account
provides 7+ gigs of storage) and one-way: if an attacker breaks into my
server, he can see what address I'm sending backups to, but is going to
have a difficult time accessing and altering those backups.

But email is sent across the internets in plain text and (in my case) I do
not control the destination server. Thus, the backups must be encrypted.
I use GPG's symmetric encryption for this. It gets the job done and is
simpler than asymmetric encryption with keys.


file-backup.sh
--------------

Backup files in a directory! See source for configuration.

Nothing fancy here.


clean.sh
--------

A simple Bash script to remove files older than a given age.