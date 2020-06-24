class RoomsController < ApplicationController
  before_action :authenticate_user!

  def index
    @rooms = current_user.rooms.distinct
  end

  def intialize_room
    rooms = Room.joins(messages: :user).where(users: { id: current_user.id }) & Room.joins(messages: :user).where(users: { id: params[:id] })

    room = nil;

    if rooms.empty?
      room = Room.new
      room.save

      Message.create(user_id: params[:id], room_id: room.id, body: 'nil', unread: false)
      Message.create(user_id: current_user.id, room_id: room.id, body: 'Hi', unread: true)

      ActionCable.server.broadcast "message_notification_channel",
                                  notified_room: room,
                                  user: current_user.id,
                                  side_user: params[:id]
    else
      room = rooms[0]
    end

    redirect_to room_path(room)
  end

  def show
    @message_number = nil
    
    Room.find(params[:id]).messages.each_with_index do |message, index|
      if message.user_id == Room.find(params[:id]).side_user(current_user).id && message.unread == true
        @message_number = index if @message_number.nil?
        Message.find(message.id).update(unread: false)
      end
    end
    
    @room = Room.find(params[:id])
    @messages = @room.messages
    @rooms = current_user.rooms.distinct
    render 'index'
  end
end
