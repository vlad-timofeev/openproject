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
    class TopicCommentsEndpoint < ::API::OpenProjectAPI
      resource :comments do
        helpers ::API::V3::Activities::CommentsHelper

        get do
          @activities = ::Journal::AggregatedJournal
                          .aggregated_journals(journable: @issue.work_package,
                                               includes: %i(
                                                   customizable_journals
                                                   attachable_journals
                                                   data
                                                 ))

          @activities.map do |aggregated_journal|
            comment = @issue.comments.find_or_create_by(journal_id: aggregated_journal.id)
            ::OpenProject::Bcf::API::Comments::CommentRepresenter.new(
              comment,
              journal: aggregated_journal,
              current_user: current_user
            )
          end
        end

        params do
          requires :comment, type: String
        end
        post do
          authorize({ controller: :journals, action: :new }, context: @issue.project) do
            raise ::API::Errors::NotFound.new
          end

          call = AddWorkPackageNoteService
                     .new(user: current_user, work_package: @issue.work_package)
                     .call(params[:comment], send_notifications: false)

          if call.success?
            comment = @issue.comments.create(journal: call.result)
            status 201
            ::OpenProject::Bcf::API::Comments::CommentRepresenter.new(
              comment,
              journal: call.result,
              current_user: current_user
            )
          else
            fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
          end
        end

        route_param :uuid, regexp: /\A([\w\-]+)\z/ do
          after_validation do
            @comment = @issue.comments.find_by!(uuid: params[:uuid])
          end

          get do
            ::OpenProject::Bcf::API::Comments::CommentRepresenter.new(
              @comment,
              current_user: current_user
            )
          end

          params do
            requires :comment, type: String
          end
          put do
            authorize({ controller: :journals, action: :edit },
                      context: @issue.project) do
              raise ::API::Errors::NotFound.new
            end

            journal = @comment.journal
            if journal.update(notes: params[:comment])
              ::OpenProject::Bcf::API::Comments::CommentRepresenter.new(
                @comment,
                current_user: current_user
              )
            else
              fail ::API::Errors::ErrorBase.create_and_merge_errors(activity.errors)
            end
          end

          delete do
            # We do not support deletion
            status 501
          end
        end
      end
    end
  end
end
