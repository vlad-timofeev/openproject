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

module ::OpenProject::Bcf::API
  module Topic
    class ParseParamsService < API::V3::ParseResourceParamsService
      def initialize(user)
        super(user, representer: ::OpenProject::Bcf::API::Topic::TopicRepresenter)
      end

      private

      def parse_attributes(request_body)
        parse(request_body).tap do |attributes|
          lookup_assignee(attributes)
        end
      end

      def parse(request_body)
        representer
          .new(struct, current_user: current_user)
          .from_hash(request_body)
          .to_h
      end

      def lookup_assignee(attributes)
        return unless attributes['assigned_to']

        attributes['assigned_to'] = User.find_by(mail: attributes['assigned_to'])
      end
    end
  end
end
