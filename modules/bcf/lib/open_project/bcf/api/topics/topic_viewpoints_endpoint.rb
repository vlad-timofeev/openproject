#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Bcf::API
  module Topics
    class TopicViewpointsEndpoint < ::API::OpenProjectAPI
      resource :viewpoints do
        get do
          @issue.viewpoints.map do |entry|
            ::OpenProject::Bcf::BcfXml::ViewpointReader
              .new(entry.viewpoint)
              .to_hash
          end
        end

        post do
          # not yet implemented
          status 501
        end

        route_param :viewpoint_uuid, regexp: /\A([\w\-]+)\z/ do
          after_validation do
            @viewpoint = @issue.viewpoints.find_by!(uuid: params[:viewpoint_uuid])
          end

          get do
            ::OpenProject::Bcf::BcfXml::ViewpointReader
              .new(@viewpoint.viewpoint)
              .to_hash
          end

          get '/snapshot' do
            if snapshot = @viewpoint.snapshot
              content_type 'application/octet-stream'
              header 'Content-Disposition', "attachment; filename*=UTF-8''#{CGI.escape(snapshot.filename)}"
              file snapshot.diskfile.to_s
            else
              status 404
            end
          end

          get '/selection' do
            ::OpenProject::Bcf::BcfXml::ViewpointReader
              .new(@viewpoint.viewpoint)
              .selected_components
          end

          get '/coloring' do
            ::OpenProject::Bcf::BcfXml::ViewpointReader
              .new(@viewpoint.viewpoint)
              .colored_components
          end

          get '/visibility' do
            ::OpenProject::Bcf::BcfXml::ViewpointReader
              .new(@viewpoint.viewpoint)
              .component_visibility
          end

          get '/bitmaps' do
            # Not implemented
            status 501
          end

          route_param :bitmap_uuid do
            get do
              status 501
            end
          end
        end
      end
    end
  end
end
