class PlaylistsController < ApplicationController
  before_filter :after_token_authentication
  respond_to :json

  def after_token_authentication
    if params[:token].present?
      @user = User.find_by_authentication_token(params[:token])
      if (@user == nil)
        render :status=>403, json: {:success=>false, :error=>'Token is invalid'}
      end
    else
      render :status=>403, json: {:success=>false, :error=>'token field is missing'}
    end
  end

  def   list
    user = User.find_by_authentication_token(params[:token])
    playlists = Playlist.find_all_by_user_id(user.id)
    if playlists.nil?
      render :status=>403, json: {:success=>false, :error=>"Couldn't find any playlist"}
    else
      render :status=>200, json: {:success=>true, :list=>playlists}
    end
  end

  def   create
    user = User.find_by_authentication_token(params[:token])
    playlist = user.playlists.new(params[:playlist])
    if playlist.save
      render :status => 200, :json => {:success=>true, :message => "Playlist has been created"}
    else
      render :status => 403, :json => {:success=>false, :error => playlist.errors}
    end
  end
  

  def   delete
    user = User.find_by_authentication_token(params[:token])
    playlist = user.playlists.find_by_id(params[:playlist_id])
    if playlist.nil?
      render :status => 404, :json => {:success=>false, :error => "Cannot find playlist"}
    else
      playlist.delete
      render :status => 200, :json => {:success=>true, :message => "PLaylist has been deleted"}
    end
  end

  def   update
    user = User.find_by_authentication_token(params[:token])
    playlist = user.playlists.find_by_id(params[:playlist_id])
    if playlist.nil?
      render :status => 404, :json => {:success=>false, :error => "Cannot find playlist"}
    else
      playlist.update_attributes(params[:playlist])
      render :status => 200, :json => {:success=>true, :message => "Attributes have been updated"}
    end
  end

  def   add_tracks
    user = User.find_by_authentication_token(params[:token])
    playlist = user.playlists.find_by_id(params[:playlist_id])
    lst = params[:tracks_id]
    if playlist.nil?
      render :status => 404, :json => {:success=>false, :error => "Cannot find playlist"}
    else
      lst.each do |track_id|
        if Track.find_by_id(track_id).nil?
          render :status => 404, :json => {:success=>false, :error => "Couldn't find track"}
          return
        else
          playlist.relation_playlists.new({:track_id => track_id})
          playlist.save
        end
      end
      render :status => 200, :json => {:success=>true, :message => "Tracks have been added to the playlist"}
    end
  end

  def     delete_tracks
    user = User.find_by_authentication_token(params[:token])
    playlist = user.playlists.find_by_id(params[:playlist_id])
    lst = params[:tracks_id]
    if playlist.nil?
      render :status => 404, :json => {:success=>false, :error => "Cannot find playlist"}
    else
      lst.each do |track_id|
        relation_id = playlist.relation_playlists.find_by_track_id(track_id)
        if relation_id.nil?
          render :status => 404, :json => {:success=>false, :error => "Cannot find playlist"}
          return
        else
          relation = playlist.relation_playlists.find_by_id(relation_id)
          relation.delete
        end
      end
      render :status => 200, :json => {:success=>true, :message => "Tracks have been deleted of the playlits"}
    end
  end
  
end