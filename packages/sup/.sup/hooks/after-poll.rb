File.write("/local/mnt/data/mail/inbox/num_unread", num_inbox_total_unread)

# terminal bell
if num_inbox_total_unread >= 1 or labels.include? '!tome'
  print "\a"
end

