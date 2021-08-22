#!/bin/sh

unread=$(cat /local/mnt/data/mail/inbox/num_unread)

if [ "$unread" != "0" ]; then
    echo "Inbox: <fc=#3ADF00>$unread</fc> msgs"
else
    echo "Inbox: $unread msgs"
fi
