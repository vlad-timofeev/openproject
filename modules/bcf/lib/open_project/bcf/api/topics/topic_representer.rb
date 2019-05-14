#-- encoding: UTF-8
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

require 'roar/decorator'
require 'roar/json'

module ::OpenProject::Bcf::API
  module Topic
    class TopicRepresenter < ::Roar::Decorator
      include ::Roar::JSON::HAL

      attr_reader :current_user

      def initialize(model, current_user:)
        super model
        @current_user = current_user
      end

      property :uuid,
               as: :guid

      property :subject,
               as: :title,
               getter: ->(*) { work_package.subject }

      property :description,
               getter: ->(*) { work_package.description }

      property :author,
               as: :creation_author,
               getter: ->(*) { work_package.author&.name },
               render_nil: true

      property :assigned_to,
               getter: ->(*) { work_package.assigned_to&.name },
               render_nil: true

      property :due_date,
               getter: ->(*) { work_package.due_date&.iso8601 },
               render_nil: true

      property :priority,
               getter: ->(*) { work_package.priority&.name },
               setter: ->(fragment:, **) {
                 represented.priority = IssuePriority.find_by(name: fragment)
               },
               render_nil: true

      property :status,
               as: :topic_status,
               getter: ->(*) { work_package.status&.name },
               setter: ->(fragment:, **) {
                 represented.status = Status.find_by(name: fragment)
               },
               render_nil: true

      property :type,
               as: :topic_type,
               getter: ->(*) { work_package.type&.name },
               setter: ->(fragment:, **) {
                 represented.type = Type.find_by(name: fragment)
               },
               render_nil: true

      property :created_at,
               as: :creation_date,
               getter: ->(*) { work_package.created_at.iso8601 },
               render_nil: true

      property :updated_at,
               as: :modified_date,
               getter: ->(*) { work_package.updated_at.iso8601 },
               render_nil: true

    end
  end
end
