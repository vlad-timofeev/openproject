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
  class ProjectsEndpoint < ::API::OpenProjectAPI
    include OpenProject::StaticRouting::UrlHelpers

    resources :projects do
      get do
        Project
          .visible
          .active
          .includes(:enabled_modules)
          .where('enabled_modules.name = ?', :bcf)
          .references('enabled_modules')
          .map do |project|
          {
            project_id: project.identifier,
            name: project.name
          }
        end
      end

      route_param :id, regexp: /\A([\w\-]+)\z/ do
        after_validation do
          @project = Project.find(params[:id])
        end

        get do
          {
            project_id: @project.identifier,
            name: @project.name
          }
        end

        get '/extensions' do
          {
            topic_type: @project.types.pluck(:name),
            topic_status: Status.pluck(:name),
            priority: IssuePriority.pluck(:name),
            user_id_type: @project.users.pluck(:mail),
            project_actions: Projects::ProjectActions.build(@project, current_user)
          }
        end

        mount OpenProject::Bcf::API::Topic::TopicsByProjectEndpoint

        params do
          optional :name
        end

        put do
          @project.update(name: name)
          status 204
        end
      end
    end
  end
end
