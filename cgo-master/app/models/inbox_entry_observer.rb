class InboxEntryObserver < ActiveRecord::Observer
  
	# Delete older records, keep max size of Inbox constrained to Constants::MAX_INBOX_SIZE
  def after_create(inbox_entry)

    user = inbox_entry.user
    if user.inbox_entries.length > Constants::MAX_INBOX_SIZE
		  entries = user.inbox_entries.sort_by {|entry| entry.created_at}
			InboxEntry.delete(entries.first.id)
		end
  end
end
