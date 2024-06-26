require 'rails_helper'

describe Group do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:discussion) { create :discussion, group: group }
  let(:discarded_discussion) { create :discussion, group: group, discarded_at: Time.now }

  context "memberships" do
    it "deletes memberships assoicated with it" do
      group = create :group
      membership = group.add_member! create :user
      group.destroy
      expect { membership.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context "subgroup" do
    before :each do
      @group = create(:group)
      @subgroup = create(:group, :parent => @group)
      @group.reload
    end

    context "subgroup.full_name" do
      it "contains parent name" do
        expect(@subgroup.full_name).to eq "#{@group.name} - #{@subgroup.name}"
      end

      it "updates if parent_name changes" do
        @group.name = "bluebird"
        @group.save!
        @subgroup.reload
        expect(@subgroup.full_name).to eq "#{@group.name} - #{@subgroup.name}"
      end
    end
  end

  context "an existing hidden group" do
    before :each do
      @group = create(:group, is_visible_to_public: false)
      @user = create(:user)
    end

    it "can promote existing member to admin" do
      @group.add_member!(@user)
      @group.add_admin!(@user)
      expect(@group.admins).to include @user
    end

    it "can add a member" do
      @group.add_member!(@user)
      expect(@group.members).to include @user
    end

    it "updates the memberships_count" do
      expect { @group.add_member! @user }.to change { @group.reload.memberships_count }.by(1)
    end

    it 'sets the first admin to be the creator' do
      @group = Group.new(name: "Test group")
      @group.add_admin!(@user)
      expect(@group.creator).to eq @user
    end
  end

  describe "parent_members_can_see_discussions_is_valid?" do
    context "parent_members_can_see_discussions = true" do

      it "errors for a hidden_from_everyone subgroup" do
        expect { create(:group,
                        is_visible_to_public: false,
                        is_visible_to_parent_members: false,
                        parent: create(:group),
                        parent_members_can_see_discussions: true) }.to raise_error ActiveRecord::RecordInvalid
      end

      it "does not error for a visible to parent subgroup" do
        expect { create(:group,
                        is_visible_to_public: false,
                        is_visible_to_parent_members: true,
                        parent: create(:group),
                        parent_members_can_see_discussions: true) }.to_not raise_error
      end
    end
  end

  describe 'cached discussions counts' do
    before do
      discussion
      discarded_discussion
    end

    it 'does not count a discarded discussion' do
      expect(group.public_discussions_count).to eq 0
      expect(group.open_discussions_count).to eq 1
      expect(group.closed_discussions_count).to eq 0
      expect(group.discussions_count).to eq 1
    end
  end

  describe 'archival' do
    before do
      group.add_member!(user)
      group.archive!
    end

    describe '#archive!' do

      it 'sets archived_at on the group' do
        group.archived_at.should be_present
      end
    end

    describe '#unarchive!' do
      before do
        group.unarchive!
      end

      it 'restores archived_at to nil on the group' do
        group.reload.archived_at.should be_nil
      end
    end
  end

  describe 'id_and_subgroup_ids' do
    let(:group) { create(:group) }
    let(:subgroup) { create(:group, parent: group) }

    it 'returns empty for new group' do
      expect(build(:group).id_and_subgroup_ids).to be_empty
    end

    it 'returns the id for groups with no subgroups' do
      expect(group.id_and_subgroup_ids).to eq [group.id]
    end

    it 'returns the id and subgroup ids for group with subgroups' do
      subgroup; group.reload
      expect(group.id_and_subgroup_ids).to include group.id
      expect(group.id_and_subgroup_ids).to include subgroup.id
    end
  end

  describe "org members count" do
    let!(:group) { create(:group) }
    let!(:subgroup) { create(:group, parent: group) }
    it 'returns total number of memberships in the org' do
      expect(group.memberships.count + subgroup.memberships.count).to eq 3
      expect(group.org_members_count).to eq 2
    end
  end
end
