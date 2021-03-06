class AttendancesController < ApplicationController
 
  
  before_action :set_user, only: [:edit_one_month, :update_one_month,
                                  :edit_overtime, :update_overtime,
                                  :edit_manager, :update_manager,
                                  :edit_apply_overtime, :update_apply_overtime,
                                  :edit_apply_one_month, :update_apply_one_month,
                                  :edit_apply_manager, :update_apply_manager,
                                  :log_attendances]
  before_action :logged_in_user, only: [:update,
                                        :edit_one_month, 
                                        :edit_overtime, 
                                        :edit_manager,
                                        :edit_apply_overtime,
                                        :edit_apply_one_month,
                                        :edit_apply_manager,
                                        :log_attendances]
  before_action :superior_or_correct_user, only: [:update, 
                                                  :edit_one_month, :update_one_month, 
                                                  :edit_overtime, :update_overtime, 
                                                  :edit_manager, :update_manager,
                                                  :edit_apply_overtime, :update_apply_overtime,
                                                  :edit_apply_one_month, :update_apply_one_month,
                                                  :edit_apply_manager, :update_apply_manager,
                                                  :log_attendances]
  before_action :superior_user, only: [:edit_apply_overtime, :update_apply_overtime,
                                      :edit_apply_one_month, :update_apply_one_month,
                                      :edit_apply_manager, :update_apply_manager,
                                      :log_attendances]
  before_action :set_one_month, only: [:edit_one_month,
                                       :edit_manager, 
                                       :edit_apply_overtime,
                                       :edit_apply_one_month,
                                       :edit_apply_manager,
                                       :log_attendances]

  UPDATE_ERROR_MSG = "??????????????????????????????????????????????????????????????????"

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # ????????????????????????????????????????????????????????????
    if @attendance.started_at.nil?
      if @attendance.update(started_at: Time.current.change(sec: 0), 
                            before_started_at: Time.current.change(sec: 0))
        flash[:info] = "??????????????????????????????"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update(finished_at: Time.current.change(sec: 0),
                            before_finished_at: Time.current.change(sec: 0))
        flash[:info] = "????????????????????????"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end

  def edit_one_month
    respond_to do |format|
      format.html
      format.csv do
        send_data render_to_string, filename: "???????????????.csv", type: :csv
      end
    end
  end

  def update_one_month
    ActiveRecord::Base.transaction do # ?????????????????????????????????????????????
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        unless item[:confirmation_one_month] == "??????"
          attendance.update!(item)
          unless attendance.before_started_at.present?
          attendance.update(before_started_at: attendance.started_at)
          end
          unless attendance.before_finished_at.present?
          attendance.update(before_finished_at: attendance.finished_at)
          end
          if attendance.confirmation_one_month == "??????A" || attendance.confirmation_one_month == "??????B"
          attendance.update(confirmation_user: attendance.confirmation_one_month)
          @user.update(apply_one_month: "?????????")
          end
        end
        flash[:warning] = "??????????????????????????????????????????????????????????????????????????????"
      end
    end
    flash[:success] = "1????????????????????????????????????????????????"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # ????????????????????????????????????????????????????????????
    flash[:danger] = "?????????????????????????????????????????????????????????????????????????????????"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end

  def edit_overtime
    @attendances = @user.attendances.where(id: params[:format])
  end

  def update_overtime
    ActiveRecord::Base.transaction do # ?????????????????????????????????????????????
    @attendance = Attendance.find(params[:format])
    @user = User.find(@attendance.user_id)
    @attendance.update(overtime_params)
      if @attendance.confirmation == "??????A" || @attendance.confirmation == "??????B"
         @user.update(apply: "?????????")
      end
    end
    flash[:warning] = "??????????????????????????????????????????????????????????????????"
    flash[:info] = "????????????????????????????????????"
    redirect_to @user
  rescue ActiveRecord::RecordInvalid # ????????????????????????????????????????????????????????????  
    flash[:danger] = "?????????????????????????????????????????????????????????????????????????????????"
    redirect_to attendances_edit_overtime_user_url(date: params[:date])
  end

  def edit_apply_overtime
    @users = User.where(apply: "?????????")
  end

  def update_apply_overtime
    ActiveRecord::Base.transaction do # ?????????????????????????????????????????????     
      apply_overtime_params.each do |id, item| 
      attendance = Attendance.find(id)
      user = User.find(attendance.user_id)
        unless (item[:change] == "0" && item[:confirmation] == "??????") ||
               (item[:change] == "0" && item[:confirmation] == "??????") ||
               (item[:change] == "1" && item[:confirmation] == "??????") ||
               (item[:change] == "0" && item[:confirmation] == "??????")
              attendance.update!(item)            
              user.update(apply: "0") 
        else
          flash[:warning] = "????????????????????????????????????????????????????????????????????????"
        end
      end
      @apply = User.where(apply: "0")
      @apply.each do |user|
        user.attendances.each do |attendance|
          if attendance.confirmation == "??????A" || attendance.confirmation == "??????B"
             user.update(apply: "?????????")
          end
        end
      end
    end
    
    flash[:success] = "????????????????????????????????????"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # ????????????????????????????????????????????????????????????
    flash[:danger] = "?????????????????????????????????????????????????????????????????????????????????"
    redirect_to attendances_edit_apply_overtime_user_url(date: params[:date])
  end
  
  def edit_apply_one_month
    @users = User.where(apply_one_month: "?????????")
  end

  def update_apply_one_month
    ActiveRecord::Base.transaction do # ?????????????????????????????????????????????
      apply_one_month_params.each do |id, item|
        attendance = Attendance.find(id)
        user = User.find(attendance.user_id)
        unless (item[:confirmation_one_month] == "??????" && item[:change_one_month] == "0") ||
               (item[:confirmation_one_month] == "??????" && item[:change_one_month] == "0") ||
               (item[:confirmation_one_month] == "??????" && item[:change_one_month] == "1") ||
               (item[:confirmation_one_month] == "??????" && item[:change_one_month] == "0")
              attendance.update!(item)
              attendance.update(apply_time:Time.now)            
              user.update(apply_one_month: "0")   
        end
        flash[:warning] = "????????????????????????????????????????????????????????????????????????"
      end
      @apply = User.where(apply_one_month: "0")
      @apply.each do |user|
        user.attendances.each do |attendance|
          if attendance.confirmation_one_month == "??????A" || attendance.confirmation_one_month == "??????B"
             user.update(apply_one_month: "?????????")
          end
        end
      end
    end
    flash[:success] = "??????????????????????????????????????????"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # ????????????????????????????????????????????????????????????
    flash[:danger] = "?????????????????????????????????????????????????????????????????????????????????"
    redirect_to attendances_edit_apply_one_month_user_url(date: params[:date])
  end
  

  def edit_manager
  end

  def update_manager
    ActiveRecord::Base.transaction do # ?????????????????????????????????????????????
    attendance = Attendance.find_by(worked_on: params[:date], user_id: params[:id])
    attendance.update!(manager_params)
    if attendance.confirmation_manager == "??????A" || attendance.confirmation_manager == "??????B"
      @user.update(apply_manager: "?????????")
    end
    flash[:success] = "1????????????????????????????????????????????????"
    redirect_to user_url(date: params[:date])
    end
  rescue ActiveRecord::RecordInvalid # ????????????????????????????????????????????????????????????
    flash[:danger] = "?????????????????????????????????????????????????????????????????????????????????"
    redirect_to user_url(date: params[:date])
  end

  def edit_apply_manager
    @users = User.where(apply_manager: "?????????")
  end

  def update_apply_manager
    ActiveRecord::Base.transaction do # ?????????????????????????????????????????????
      apply_manager_params.each do |id, item|
        attendance = Attendance.find(id)
        user = User.find(attendance.user_id)
        unless (item[:confirmation_manager] == "??????" && item[:change_manager] == "0") ||
               (item[:confirmation_manager] == "??????" && item[:change_manager] == "0") ||
               (item[:confirmation_manager] == "??????" && item[:change_manager] == "1") ||
               (item[:confirmation_manager] == "??????" && item[:change_manager] == "0")
              attendance.update!(item)            
              user.update(apply_manager: "0")   
        end
        flash[:warning] = "????????????????????????????????????????????????????????????????????????"
      end
      @apply = User.where(apply_manager: "0")
      @apply.each do |user|
        user.attendances.each do |attendance|
          if attendance.confirmation_manager == "??????A" || attendance.confirmation_manager == "??????B"
             user.update(apply_manager: "?????????")
          end
        end
      end
    end
    flash[:success] = "?????????????????????????????????????????????"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # ????????????????????????????????????????????????????????????
    flash[:danger] = "?????????????????????????????????????????????????????????????????????????????????"
    redirect_to attendances_edit_apply_manager_user_url(date: params[:date])
  end

  def log_attendances
    years = {}
    months = {}
    @attendances = Attendance.where(confirmation_one_month: "??????")

    if params[:year].present? && params[:month].present?
      year = params[:year]            # => "2022"
      month = params[:month]          # => "5"
      month = format("%02d", month)   # => "05"
      @attendances = Attendance.all  
     
      @attendances.each do |at|
        years.store(at.id, at.worked_on.strftime("%Y"))     # => [id: "1", %Y: "2022"] next [id: "2", %Y: "2022"]
        months.store(at.id, at.worked_on.strftime("%m"))    # => [id: "1", %Y: "05"] next [id: "2", %Y: "05"]
      end
        # ??????????????????=>??????????????? {id: "1", worked_on: "2022-05-01"} => [[id: "1"],[worked_on: "2022-05-01"]]
      years = years.to_a 
      months = months.to_a

      attendance_id_1 = []
      years.each do |y|               # => [1, "2022"]
        if y[1] == year               # y[1] => ?????????????????? "2022"
          attendance_id_1 << y[0]
        end
      end
      attendance_id_2 = []
      months.each do |m| # => [1, "05"]
        if m[1] == month
          attendance_id_2 << m[0]
        end
      end
      attendance_date_id = attendance_id_1 + attendance_id_2
      attendance_date_id = attendance_date_id.select{|a| attendance_date_id.index(a)!=attendance_date_id.rindex(a)}.uniq
      @attendances = Attendance.where(id: attendance_date_id)
    end

  end

  private

    # 1??????????????????????????????????????????
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :next_day, :note, :confirmation_one_month, :change_one_month])[:attendances]
    end

    def apply_overtime_params
      params.require(:user).permit(attendances: [:confirmation, :change])[:attendances]
    end

    def apply_one_month_params
      params.require(:user).permit(attendances: [:confirmation_one_month, :change_one_month])[:attendances]
    end

    def overtime_params
      params.require(:user).permit(attendance: [:scheduled_end_time, :next_day, :business_process, :confirmation])[:attendance]
    end

    def manager_params
      params.require(:user).permit(attendance: [:confirmation_manager])[:attendance]
    end

    def apply_manager_params
      params.require(:user).permit(attendances: [:confirmation_manager, :change_manager])[:attendances]
    end

    # before???????????????

    
end