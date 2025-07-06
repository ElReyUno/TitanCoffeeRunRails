# Order Policy
class OrderPolicy < ApplicationPolicy
  def show?
    user == record.user || user.admin?
  end

  def create?
    user.present?
  end

  def update?
    user.admin? || (user == record.user && record.can_be_cancelled?)
  end

  def destroy?
    user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
