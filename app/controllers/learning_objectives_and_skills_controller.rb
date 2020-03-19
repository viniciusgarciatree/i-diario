class LearningObjectivesAndSkillsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @learning_objectives_and_skills = apply_scopes(LearningObjectivesAndSkill.ordered)

    authorize @learning_objectives_and_skills
  end

  def new
    @learning_objectives_and_skill = LearningObjectivesAndSkill.new

    authorize @learning_objectives_and_skill
  end

  def create
    @learning_objectives_and_skill = LearningObjectivesAndSkill.new(learning_objectives_and_skills_params)

    authorize @learning_objectives_and_skill

    if @learning_objectives_and_skill.save
      respond_with @learning_objectives_and_skill, location: learning_objectives_and_skills_path
    else
      render :new
    end
  end

  def edit
    @learning_objectives_and_skill = LearningObjectivesAndSkill.find(params[:id])

    authorize @learning_objectives_and_skill
  end

  def update
    @learning_objectives_and_skill = LearningObjectivesAndSkill.find(params[:id])

    authorize @learning_objectives_and_skill

    if @learning_objectives_and_skill.update(learning_objectives_and_skills_params)
      respond_with @learning_objectives_and_skill, location: learning_objectives_and_skills_path
    else
      render :edit
    end
  end

  def destroy
    @learning_objectives_and_skill = LearningObjectivesAndSkill.find(params[:id])

    authorize @learning_objectives_and_skill

    @learning_objectives_and_skill.destroy

    respond_with(
      @learning_objectives_and_skill,
      location: learning_objectives_and_skills_path,
      alert: @learning_objectives_and_skill.errors.to_a
    )
  end

  def history
    @learning_objectives_and_skill = LearningObjectivesAndSkill.find params[:id]

    authorize @learning_objectives_and_skill

    respond_with @learning_objectives_and_skill
  end

  def contents
    @contents = []

    query = LearningObjectivesAndSkill.ordered
    query = query.where(field_of_experience: params[:experience_fields]) if params[:experience_fields]
    query = query.where(discipline: params[:disciplines]) if params[:disciplines]
    query.each do |skill|
      @contents << {
        description: "(#{skill.code}) #{skill.description}"
      }
    end

    respond_with(contents: @contents)
  end

  private

  def learning_objectives_and_skills_params
    params.require(:learning_objectives_and_skill).permit(
      :code,
      :description,
      :step,
      :field_of_experience,
      :discipline,
      :thematic_unit
    )
  end
end