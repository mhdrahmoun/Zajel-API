json.messages do
  json.array! @messages do |message|
    json.id message.id
    json.conversation_id message.conversation_id
    json.content message.content
    json.sender_type message.sender_type
    json.sender_id message.sender_id
    json.sender_name message.sender_name
    json.created_at message.created_at
  end
end