class BookActivity < ApplicationRecord
  belongs_to :book
  belongs_to :borrower, polymorphic: true
  belongs_to :lender, polymorphic: true
  belongs_to :conversation, optional: true

  enum status: [:pending, :accepted, :rejected]

  before_validation :set_lender
  after_create :notify_lender
  after_update :notify_borrower, if: :saved_change_to_status?
  after_update :create_conversation, if: :accepted?
  after_update :update_book_status, if: :accepted?

  scope :active, -> { where.not(status: :rejected) }

  def set_lender
    self.lender = book.owner
  end

  def update_book_status
    book.borrowed!
  end

  def create_conversation
    conversation = Conversation.find_or_create_by(borrower: borrower, lender: lender)
    self.update_columns(conversation_id: conversation.id)
  end

  def notify_lender
    Notification.create(
        content: "#{borrower.full_name} wants to borrow #{book.title}",
        payload: {
            title: 'You have got a new borrow request',
            subject: "#{borrower.full_name} wants to borrow #{book.title}"
        },
        recipient: lender
    )
  end

  def notify_borrower
    content, title = if accepted?
                       [
                           "#{lender.full_name} accepted you request to borrow (#{book.title})",
                           'request accepted'
                       ]
                     elsif rejected?
                        [
                            "#{lender.full_name} rejected you request to borrow (#{book.title})",
                            'request rejected'
                        ]
                     else
                       return nil
    end
    Notification.create(
        content: content,
        payload: {
            title: title,
            subject: content
        },
        recipient: borrower
    )
  end
end