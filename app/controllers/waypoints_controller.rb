class WaypointsController < ApplicationController
  before_action :set_flight
  before_action :set_waypoint, only: %i[edit update destroy]

  def new
    @waypoint = @flight.waypoints.build number: @flight.waypoints.count + 1
  end

  def index
    wps = Settings.theaters[@flight.theater].waypoints.map do |wp|
      { name: wp.name, pos: position(wp) }
    end
    wps = wps.select { |wp| wp[:name].downcase.include? params[:q].downcase } if params[:q]
    render json: wps
  end

  def edit; end

  def create
    params[:waypoint].delete_if{ |_k, v| v.empty? }
    @waypoint = @flight.waypoints.build(waypoint_params)

    respond_to do |format|
      if @waypoint.save
        format.js
        format.html { redirect_to flight_path(@flight), notice: 'Waypoint was successfully created.' }
      else
        format.js
        format.html { render :new }
      end
    end
  end

  def update
    respond_to do |format|
      if @waypoint.update(waypoint_params)
        format.js
        format.html { redirect_to flight_path(@flight), notice: 'Waypoint was successfully updated.' }
      else
        format.js
        format.html { render :edit }
      end

    end
  end

  def destroy
    @waypoint.destroy
    redirect_to flight_path(@flight), notice: 'Waypoint was successfully destroyed.'
  end

  def copy_from
    @flight.waypoints.destroy_all
    src_flight = Flight.find params[:waypoints][:flight]
    src_flight.waypoints.each do |wp|
      new_wp = wp.dup
      new_wp.flight = @flight
      new_wp.save!
    end
    redirect_to flight_path(@flight), notice: 'Waypoints successfully copied.'
  end

  private

  def set_flight
    @flight = Flight.find(params[:flight_id])
  end

  def set_waypoint
    @waypoint = @flight.waypoints.find(params[:id])
  end

  def waypoint_params
    params.require(:waypoint).permit(:name, :position, :altitude, :tot)
  end

  def position(wp)
    pos = Position.new(latitude: wp.lat, longitude: wp.lon, pos: wp.pos)
    pos = pos.to_s(type: (@flight.airframe == 'f18' || @flight.airframe == 'av8b' ? :dms : :dm))
    return "#{wp.dme} (#{pos})" if wp.dme.present?

    pos
  end
end
