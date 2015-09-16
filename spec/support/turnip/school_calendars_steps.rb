module Turnip
  module SchoolCalendarSteps
    step 'que as unidades estão sincronizadas com o i-Educar' do
      VCR.use_cassette('unities') do
        unities = UnitiesParser.parse!(IeducarApiConfiguration.current)
        unities.each do |unity|
          create(:unity, name: unity[:name],
                         api_code: unity[:api_code])
        end

        sleep 2
      end
    end

    step 'que acesso a listagem de calendários letivos' do
      click_***REMOVED*** 'Calendário letivo'
    end

    step 'eu clicar em Sincronizar' do
      VCR.use_cassette('school_calendars') do
        click_on 'Sincronizar'

        sleep 2
      end
    end

    step 'poderei sincronizar novos calendários letivos do i-Educar' do
      find('#select-all-unities').trigger('click')

      find('button[type=submit]').trigger('click')

      expect(page).to have_content('Calendários letivos sincronizados com sucesso.')
    end

    step 'que existe um calendário letivo cadastrada' do
      click_***REMOVED*** 'Calendário letivo'

      within '#resources > tbody > tr:nth-child(1)' do
        expect(page).to have_content "2015"
      end
    end

    step 'entro na tela de edição deste calendário letivo' do
      within '#resources > tbody > tr:nth-child(1)' do
        click_on 'Editar'
      end
    end

    step 'poderei alterar os dados deste calendário letivo' do
      fill_in 'Número de aulas por turno', with: '3'

      click_on 'Salvar'

      expect(page).to have_content 'Calendário letivo foi alterado com sucesso.'
      expect(page).to have_content '3'
    end

    step 'poderei excluir um calendário letivo' do
      within '#resources > tbody > tr:nth-child(1)' do
        expect(page).to have_content "2015"
        click_link "Excluir"
      end

      expect(page).to have_content 'Calendário letivo foi apagado com sucesso'

      within '#resources > tbody' do
        expect(page).to have_no_content '2015'
      end
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::SchoolCalendarSteps
end
