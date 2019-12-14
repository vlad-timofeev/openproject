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

require 'spec_helper'

shared_examples "DeliverWatcherNotificationJob" do
  let(:project) { FactoryBot.create(:project) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }
  let(:watcher_setter) { FactoryBot.create(:user) }
  let(:watcher_user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:watcher) { FactoryBot.create(:watcher, watchable: work_package, user: watcher_user) }

  subject { described_class.new.perform(work_package.id, watcher_user.id, watcher_setter.id, is_watching) }

  before do
    # make sure no actual calls make it into the UserMailer
    allow(UserMailer).to receive(:work_package_watcher_toggled)
      .and_return(double('mail', deliver_now: nil))
  end

  it 'sends a mail' do
    expect(UserMailer).to receive(:work_package_watcher_toggled).with(work_package,
                                                                    watcher_user,
                                                                    watcher_setter,
                                                                    is_watching)
    subject
  end

  describe 'exceptions' do
    describe 'exceptions should be raised' do
      before do
        mail = double('mail')
        allow(mail).to receive(:deliver_now).and_raise(SocketError)
        expect(UserMailer).to receive(:work_package_watcher_toggled).and_return(mail)
      end

      it 'raises the error' do
        expect { subject }.to raise_error(SocketError)
      end
    end
  end
end

describe DeliverWatcherRemovedNotificationJob, type: :model do
  include_examples "DeliverWatcherNotificationJob" do
    let(:is_watching) { true }
  end
end

describe DeliverWatcherRemovedNotificationJob, type: :model do
  include_examples "DeliverWatcherNotificationJob" do
    let(:is_watching) { false }
  end
end
