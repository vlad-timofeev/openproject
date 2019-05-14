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
  module Topic
    class TopicsByProjectEndpoint < ::API::OpenProjectAPI
      include OpenProject::StaticRouting::UrlHelpers

      resources :topics do
        helpers ::API::V3::WorkPackages::WorkPackagesSharedHelpers

        get do
          ::Bcf::Issue
            .in_project(@project)
            .includes(:work_package)
            .map do |issue|
            Topic::TopicRepresenter.new(issue, current_user: current_user)
          end
        end

        route_param :uuid, regexp: /\A([\w\-]+)\z/ do
          after_validation do
            @issue = ::Bcf::Issue.in_project(@project).find_by!(uuid: params[:uuid])
          end

          get do
            Topic::TopicRepresenter.new @issue, current_user: current_user
          end

          put do
            authorize(:edit_work_packages, context: @project)
            parameters = ::OpenProject::Bcf::API::Topic::ParseParamsService
                           .new(current_user)
                           .call(request_body)
                           .result

            call = ::WorkPackages::UpdateService
                     .new(
                       user: current_user,
                       work_package: @issue.work_package
                     )
                     .call(attributes: parameters, send_notifications: notify_according_to_params)

            if call.success?
              @issue.reload
              Topic::TopicRepresenter.new @issue, current_user: current_user
            else
              handle_work_package_errors @issue.work_package, call
            end
          end

          delete do
            authorize(:delete_work_packages, context: @project)

            call = ::WorkPackages::DestroyService
                     .new(
                       user: current_user,
                       work_package: @issue.work_package
                     )
                     .call

            if call.success?
              status 204
            else
              fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
            end
          end

          mount TopicSnippetEndpoint
          mount TopicFilesEndpoint
          mount TopicCommentsEndpoint
          mount TopicViewpointsEndpoint
          mount RelatedTopicsEndpoint
        end
      end
    end
  end
end
