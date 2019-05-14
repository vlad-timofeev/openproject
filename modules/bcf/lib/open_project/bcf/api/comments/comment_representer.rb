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
  module Comments
    class CommentRepresenter < ::Roar::Decorator
      include ::Roar::JSON::HAL

      attr_reader :current_user, :comment

      def initialize(comment, journal: nil, current_user:)
        super(journal || comment.journal)
        @comment = comment
        @current_user = current_user
      end

      property :uuid,
               as: :guid,
               exec_context: :decorator,
               getter: ->(*) { comment.uuid }

      property :notes,
               as: :comment

      property :topic_guid,
               exec_context: :decorator,
               getter: ->(*) { comment.issue.uuid }

      property :created_at,
               as: :date,
               getter: ->(*) { created_at.iso8601 }

      property :author,
               getter: ->(*) { user&.name }

    end
  end
end
