#
# Labeling Rules
#

num_labels = message.labels.length
tome = false

# General mailing lists
if message.recipients.any? { |t| ["boulder.classified", "boulder.restaurants"].any? { |p| t.email.start_with? p } }
  message.add_label "boulder.classified"
end

# Archive messages with labels
if message.labels.length > num_labels and !tome
  message.remove_label "inbox"
end

