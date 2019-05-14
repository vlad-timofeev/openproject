##
# Extracts sections of a BCF markup file
# manually. If we want to extract the entire markup,
# this should be turned into a representable/xml decorator
require_relative 'file_entry'

module OpenProject::Bcf::BcfXml
  class ViewpointReader
    attr_reader :viewpoint_xml,
                :doc,
                :main_node

    def initialize(viewpoint_xml)
      @viewpoint_xml = viewpoint_xml
      @doc = Nokogiri::XML viewpoint_xml
      @main_node = doc.xpath('VisualizationInfo')[0]
    end

    def to_hash
      {
        guid: main_node['Guid'],
        perspective_camera: build_perspective_camera,
        lines: build_lines,
        clipping_planes: build_clipping_planes,
        components: {
          selection: selected_components,
          coloring: colored_components,
          visibility: component_visibility
        }
      }.compact
    end

    def selected_components
      main_node.xpath('Components/Selection/Component').map(&method(:build_component_entry))
    end

    def colored_components
      main_node.xpath('Components/Coloring/Color').map do |node|
        {
          color: node['Color'],
          components: node.xpath('Component').map(&method(:build_component_entry))
        }
      end
    end

    def component_visibility
      visibility = { view_setup_hints: build_setup_hints }

      visibility_node = main_node.xpath('Components/Visibility')[0]
      return hash if visibility_node.nil?

      if visibility_node
        visibility[:default_visibility] = ActiveRecord::Type::Boolean.new.cast(visibility_node['DefaultVisibility'])
        visibility[:exceptions] = visibility_node.xpath('Exceptions/Component').map(&method(:build_component_entry))
      end

      visibility
    end

    private

    def build_setup_hints
      node = main_node.xpath('Components/ViewSetupHints')
      %w[spaces_visible space_boundaries_visible openings_visible]
        .map do |key|
        value = node.xpath("@#{key.camelize}").text
        [key, ActiveRecord::Type::Boolean.new.cast(value)]
      end.to_h
    end

    ##
    # Extract a single component entry
    # @param node Component node
    def build_component_entry(node)
      {
        ifc_guid: node['IfcGuid'],
        originating_system: node['OriginatingSystem'],
        authoring_tool_id: node['AuthoringToolId'],
      }.compact
    end

    def build_lines
      main_node.xpath('Lines/Line').map do |line_node|
        {
          start_point: build_coordinates(line_node.xpath('StartPoint')),
          end_point: build_coordinates(line_node.xpath('EndPoint'))
        }
      end
    end

    def build_clipping_planes
      main_node.xpath('ClippingPlanes/ClippingPlane').map do |plane|
        {
          location: build_coordinates(plane.xpath('Location')),
          direction: build_coordinates(plane.xpath('Direction'))
        }
      end
    end

    def build_perspective_camera
      %w[camera_view_point camera_direction camera_up_vector]
        .map do |key|
        node = main_node.xpath("PerspectiveCamera/#{key.camelize}")[0]
        [key, build_coordinates(node)]
      end
        .to_h
    end

    ##
    # Extract x,y,z nodes into hash under the given path
    def build_coordinates(node)
      %w(x y z)
        .map do |key|
        [key, node.xpath(key.upcase).text]
      end
        .to_h
    end
  end
end
