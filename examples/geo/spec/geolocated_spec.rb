require          'gorillib/data_munging'
require_relative '../geolocated'

describe Wukong::Geolocated do
  let(:aus_lng){   -97.759003 } # Austin, TX -- infochimps HQ
  let(:aus_lat){    30.273884 }
  let(:sat_lng){   -98.486123 } # San Antonio, TX
  let(:sat_lat){    29.42575  }
  let(:dpi){ 72 }
  #
  let(:aus_tile_x_3){  1.82758 } # zoom level 3
  let(:aus_tile_y_3){  3.29356 }
  let(:aus_pixel_x_3){ 468     }
  let(:aus_pixel_y_3){ 843     }
  #
  let(:aus_tile_x_8){   58.48248675555555 } # zoom level 8
  let(:aus_tile_y_8){  105.39405073699557 }
  let(:aus_tile_x_11){ 467 } # zoom level 11
  let(:aus_tile_y_11){ 843 }
  #
  let(:aus_quadkey  ){ "0231301203311211" }
  let(:aus_quadkey_3){ "023"             }
  let(:radius){      1_000_000 } # 1,000 km

  context Wukong::Geolocated::ByCoordinates do
    let(:point_klass) do
      module Wukong
        class TestPoint
          include Gorillib::Model
          include Wukong::Geolocated::ByCoordinates
          field :name,       String, position: 0,   doc: "Name of this location"
          field :longitude,  Float,  position: 1,   doc: "Longitude (X) of a point, in decimal degrees"
          field :latitude,   Float,  position: 2,   doc: "Latitude (Y) of a point, in decimal degrees"
        end
      end
      Wukong::TestPoint
    end
    subject{ point_klass.new("Infochimps HQ", aus_lng, aus_lat) }

    context '#tile_xf' do
      it "tile X coordinate, as a float" do
        subject.tile_xf(3).should  be_within(0.0001).of( 1.82758)
        subject.tile_xf(8).should  be_within(0.0001).of(58.48248)
        subject.tile_xf(11).should be_within(0.0001).of(467.8598)
      end
    end
    context '#tile_x' do
      it "tile X coordinate, as an integer" do
        subject.tile_x(3).should  ==   1
        subject.tile_x(8).should  ==  58
        subject.tile_x(11).should == 467
      end
    end
    context '#tile_yf' do
      it "tile Y coordinate, as a float" do
        subject.tile_yf(3).should  be_within(0.0001).of(  3.29356)
        subject.tile_yf(8).should  be_within(0.0001).of(105.394051)
        subject.tile_yf(11).should be_within(0.0001).of(843.152406)
      end
    end
    context '#tile_x' do
      it "tile Y coordinate, as an integer" do
        subject.tile_y(3).should  ==   3
        subject.tile_y(8).should  == 105
        subject.tile_y(11).should == 843
      end
    end
    context '#quadkey' do
      it "a string of 2-bit tile selectors" do
        subject.quadkey(3).should  == "023"
        subject.quadkey(16).should == "0231301203311211"
      end
    end
  end

  context Wukong::Geolocated do

    it "gives private methods on including class as well as the methods on itself" do
      klass = Class.new{ include Wukong::Geolocated }
      klass.should be_private_method_defined(:lng_lat_zl_to_tile_xy)
      klass.should be_private_method_defined(:haversine_distance)
    end

    #
    # Tile coordinates
    #

    it "returns a map tile size given a zoom level" do
      Wukong::Geolocated.map_tile_size(3).should == 8
    end

    it "returns a tile_x, tile_y pair given a longitude, latitude and zoom level" do
      Wukong::Geolocated.lng_lat_zl_to_tile_xy(aus_lng, aus_lat,  8).should == [ 58, 105]
      Wukong::Geolocated.lng_lat_zl_to_tile_xy(aus_lng, aus_lat, 11).should == [467, 843]
    end

    it "returns a longitude, latitude pair given tile_x, tile_y and zoom level" do
      lng, lat = Wukong::Geolocated.tile_xy_zl_to_lng_lat(aus_tile_x_8, aus_tile_y_8, 8)
      lng.should be_within(0.0001).of(aus_lng)
      lat.should be_within(0.0001).of(aus_lat)
    end

    #
    # Pixel coordinates
    #

    it "returns a map pizel size given a zoom level" do
      Wukong::Geolocated.map_pixel_size(3).should == 2048
    end

    it "returns a pixel_x, pixel_y pair given a longitude, latitude and zoom level" do
      Wukong::Geolocated.lng_lat_zl_to_pixel_xy(aus_lng, aus_lat, 3).should == [468, 843]
    end

    it "returns a longitude, latitude pair given pixel_x, pixel_y and zoom level" do
      lng, lat = Wukong::Geolocated.pixel_xy_zl_to_lng_lat(aus_pixel_x_3, aus_pixel_y_3, 3)
      lat.round(4).should ==  30.2970
      lng.round(4).should == -97.7344
    end

    it "returns a tile x-y pair given a pixel x-y pair" do
      Wukong::Geolocated.pixel_xy_to_tile_xy(aus_pixel_x_3, aus_pixel_y_3).should == [1,3]
    end

    it "returns a pixel x-y pair given a float tile x-y pair" do
      Wukong::Geolocated.tile_xy_to_pixel_xy(aus_tile_x_3,      aus_tile_y_3     ).should == [467.86048, 843.15136]
    end

    it "returns a pixel x-y pair given an integer tile x-y pair" do
      Wukong::Geolocated.tile_xy_to_pixel_xy(aus_tile_x_3.to_i, aus_tile_y_3.to_i).should == [256, 768]
    end

    #
    # Quadkey coordinates
    #

    it "returns a quadkey given a tile x-y pair and a zoom level" do
      Wukong::Geolocated.tile_xy_zl_to_quadkey(aus_tile_x_3,  aus_tile_y_3,  3).should == "023"
      Wukong::Geolocated.tile_xy_zl_to_quadkey(aus_tile_x_8,  aus_tile_y_8,  8).should == "02313012"
      Wukong::Geolocated.tile_xy_zl_to_quadkey(aus_tile_x_11, aus_tile_y_11,11).should == "02313012033"
    end

    it "returns a quadkey given a longitude, latitude and a zoom level" do
      Wukong::Geolocated.lng_lat_zl_to_quadkey(aus_lng, aus_lat,  3).should == "023"
      Wukong::Geolocated.lng_lat_zl_to_quadkey(aus_lng, aus_lat,  8).should == "02313012"
      Wukong::Geolocated.lng_lat_zl_to_quadkey(aus_lng, aus_lat, 11).should == "02313012033"
      Wukong::Geolocated.lng_lat_zl_to_quadkey(aus_lng, aus_lat, 16).should == "0231301203311211"
    end

    it "returns a packed quadkey (an integer) given a tile xy and zoom level" do
      Wukong::Geolocated.tile_xy_zl_to_packed_qk(aus_tile_x_3.floor,  aus_tile_y_3.floor,  3).should == "023".to_i(4)
      Wukong::Geolocated.tile_xy_zl_to_packed_qk(aus_tile_x_8.floor,  aus_tile_y_8.floor,  8).should == "02313012".to_i(4)
      Wukong::Geolocated.tile_xy_zl_to_packed_qk(aus_tile_x_11.floor, aus_tile_y_11.floor,11).should == "02313012033".to_i(4)
    end

    context '.packed_qk_zl_to_tile_xy' do
      let(:packed_qk){ "0231301203311211".to_i(4) }
      it "returns a tile xy given a packed quadkey (integer)" do
        Wukong::Geolocated.packed_qk_zl_to_tile_xy(packed_qk >> 26,  3).should == [  1,   3,  3]
        Wukong::Geolocated.packed_qk_zl_to_tile_xy(packed_qk >> 16,  8).should == [ 58, 105,  8]
        Wukong::Geolocated.packed_qk_zl_to_tile_xy(packed_qk >> 10, 11).should == [467, 843, 11]
      end

      it "defaults to zl=16 for packed quadkeys" do
        Wukong::Geolocated.packed_qk_zl_to_tile_xy(packed_qk    ).should == [14971, 26980, 16]
        Wukong::Geolocated.packed_qk_zl_to_tile_xy(packed_qk, 16).should == [14971, 26980, 16]
      end
    end

    it "returns tile x-y pair and a zoom level given a quadkey" do
      Wukong::Geolocated.quadkey_to_tile_xy_zl(aus_quadkey[0..2] ).should == [1, 3, 3]
      Wukong::Geolocated.quadkey_to_tile_xy_zl(aus_quadkey[0..7] ).should == [aus_tile_x_8.floor,  aus_tile_y_8.floor,  8]
      Wukong::Geolocated.quadkey_to_tile_xy_zl(aus_quadkey[0..10]).should == [aus_tile_x_11.floor, aus_tile_y_11.floor, 11]
    end

    it "allows '' to be a quadkey (whole map)" do
      Wukong::Geolocated.quadkey_to_tile_xy_zl("").should == [0, 0, 0]
    end

    it "maps tile xyz [0,0,0] to quadkey ''" do
      Wukong::Geolocated.tile_xy_zl_to_quadkey(0,0,0).should == ""
    end

    it "throws an error if a bad quadkey is given" do
      expect{ Wukong::Geolocated.quadkey_to_tile_xy_zl("bad_key") }.to raise_error(ArgumentError, /Quadkey.*characters/)
    end

    it "returns a bounding box given a quadkey" do
      left, btm, right, top = Wukong::Geolocated.quadkey_to_bbox(aus_quadkey_3)
      left.should  be_within(0.0001).of(-135.0)
      right.should be_within(0.0001).of(- 90.0)
      btm.should   be_within(0.0001).of(   0.0)
      top.should   be_within(0.0001).of(  40.9799)
    end

    it "returns the smallest quadkey containing two points" do
      Wukong::Geolocated.quadkey_containing_bbox(aus_lng, aus_lat, sat_lng, sat_lat).should == "023130"
    end

    it "returns a bounding box given a point and radius" do
      left, btm, right, top = Wukong::Geolocated.lng_lat_rad_to_bbox(aus_lng, aus_lat, radius)

      left.should  be_within(0.0001).of(-108.1723)
      right.should be_within(0.0001).of(- 87.3457)
      btm.should   be_within(0.0001).of(  21.2807)
      top.should   be_within(0.0001).of(  39.2671)
    end

    it "returns a centroid given a bounding box" do
      mid_lng, mid_lat = Wukong::Geolocated.bbox_centroid([aus_lng, sat_lat], [sat_lng, aus_lat])
      mid_lng.should be_within(0.0001).of(-98.1241)
      mid_lat.should be_within(0.0001).of( 29.8503)
    end

    it "returns a pixel resolution given a latitude and zoom level" do
      Wukong::Geolocated.pixel_resolution(aus_lat, 3).should be_within(0.0001).of(16880.4081)
    end

    it "returns a map scale given a latitude, zoom level and dpi" do
      Wukong::Geolocated.map_scale_for_dpi(aus_lat, 3, dpi).should be_within(0.0001).of(47849975.8302)
    end

    it "calculates the haversine distance between two points" do
      Wukong::Geolocated.haversine_distance(aus_lng, aus_lat, sat_lng, sat_lat).should be_within(0.0001).of(117522.1219)
    end

    it "calculates the haversine midpoint between two points" do
      lng, lat = Wukong::Geolocated.haversine_midpoint(aus_lng, sat_lat, sat_lng, aus_lat)
      lng.should be_within(0.0001).of(-98.1241)
      lat.should be_within(0.0001).of( 29.8503)
    end

    it "calculates the point a given distance directly north from a lat/lng" do
      lng, lat = Wukong::Geolocated.point_north(aus_lng, aus_lat, 1000000)
      lng.should be_within(0.0001).of(-97.7590)
      lat.should be_within(0.0001).of( 39.2671)
    end

    it "calculates the point a given distance directly east from a lat/lng" do
      lng, lat = Wukong::Geolocated.point_east(aus_lng, aus_lat, 1000000)
      lng.should be_within(0.0001).of(-87.3457)
      lat.should be_within(0.0001).of( 30.2739)
    end


  end # module methods
end
