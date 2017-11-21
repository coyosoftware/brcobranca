# -*- encoding: utf-8 -*-
#

require 'spec_helper'

RSpec.describe Brcobranca::Boleto::Inter do
  let(:valid_attributes) do
    {
      valor: 0.0,
      local_pagamento: 'PAGÁVEL EM QUALQUER BANCO ATÉ O VENCIMENTO',
      cedente: 'Kivanio Barbosa',
      documento_cedente: '12345678912',
      sacado: 'Claudio Pozzebom',
      sacado_documento: '12345678900',
      conta_corrente: '61900',
      numero_documento: '15234'
    }
  end

  it 'Criar nova instancia com atributos padrões' do
    boleto_novo = described_class.new
    expect(boleto_novo.banco).to eql('077')
    expect(boleto_novo.agencia).to eql('1')
    expect(boleto_novo.especie_documento).to eql('OU')
    expect(boleto_novo.aceite).to eql('NAO')
    expect(boleto_novo.especie).to eql('R$')
    expect(boleto_novo.moeda).to eql('9')
    expect(boleto_novo.data_documento).to eql(Date.current)
    expect(boleto_novo.data_vencimento).to eql(Date.current)
    expect(boleto_novo.quantidade).to be(1)
    expect(boleto_novo.valor).to be(0.0)
    expect(boleto_novo.valor_documento).to be(0.0)
    expect(boleto_novo.local_pagamento).to eql('PAGÁVEL EM QUALQUER BANCO ATÉ O VENCIMENTO')
    expect(boleto_novo.carteira).to eql('12')
  end

  it 'Criar nova instancia com atributos válidos' do
    boleto_novo = described_class.new(valid_attributes)
    expect(boleto_novo.banco).to eql('077')
    expect(boleto_novo.agencia).to eql('1')
    expect(boleto_novo.especie_documento).to eql('OU')
    expect(boleto_novo.aceite).to eql('NAO')
    expect(boleto_novo.especie).to eql('R$')
    expect(boleto_novo.moeda).to eql('9')
    expect(boleto_novo.data_documento).to eql(Date.current)
    expect(boleto_novo.data_vencimento).to eql(Date.current)
    expect(boleto_novo.quantidade).to be(1)
    expect(boleto_novo.valor).to be(0.0)
    expect(boleto_novo.valor_documento).to be(0.0)
    expect(boleto_novo.local_pagamento).to eql('PAGÁVEL EM QUALQUER BANCO ATÉ O VENCIMENTO')
    expect(boleto_novo.cedente).to eql('Kivanio Barbosa')
    expect(boleto_novo.documento_cedente).to eql('12345678912')
    expect(boleto_novo.sacado).to eql('Claudio Pozzebom')
    expect(boleto_novo.sacado_documento).to eql('12345678900')
    expect(boleto_novo.conta_corrente).to eql('0000061900')
    expect(boleto_novo.numero_documento).to eql('0015234')
    expect(boleto_novo.carteira).to eql('12')
  end

  it 'Montar código de barras para carteira número 12' do
    valid_attributes[:valor] = 1.00
    valid_attributes[:data_documento] = Date.parse('2017-11-20')
    valid_attributes[:data_vencimento] = Date.parse('2017-11-21')
    valid_attributes[:numero_documento] = '15234'
    valid_attributes[:conta_corrente] = '919898'
    boleto_novo = described_class.new(valid_attributes)

    expect(boleto_novo.codigo_barras_segunda_parte).to eql('1000121000152340000919898')
    expect(boleto_novo.codigo_barras).to eql('07793735000000001001000121000152340000919898')
    expect(boleto_novo.codigo_barras.linha_digitavel).to eql('07791.00015 21000.152344 00009.198987 3 73500000000100')
  end

  it 'Não permitir gerar boleto com atributos inválido' do
    boleto_novo = described_class.new
    expect { boleto_novo.codigo_barras }.to raise_error(Brcobranca::BoletoInvalido)
    expect(boleto_novo.errors.count).to be(4)
  end

  it 'Montar nosso_numero_boleto' do
    boleto_novo = described_class.new(valid_attributes)

    boleto_novo.numero_documento = '00000000002'
    boleto_novo.carteira = '19'
    expect(boleto_novo.nosso_numero_boleto).to eql('19/00000000002-8')
    expect(boleto_novo.nosso_numero_dv).to be(8)

    boleto_novo.numero_documento = 6
    boleto_novo.carteira = '19'
    expect(boleto_novo.nosso_numero_boleto).to eql('19/0000006-1')
    expect(boleto_novo.nosso_numero_dv).to be(1)

    boleto_novo.numero_documento = '00000000001'
    boleto_novo.carteira = '19'
    expect(boleto_novo.nosso_numero_boleto).to eql('19/00000000001-P')
    expect(boleto_novo.nosso_numero_dv).to eql('P')
  end

  it 'Montar agencia_conta_boleto' do
    boleto_novo = described_class.new(valid_attributes)

    expect(boleto_novo.agencia_conta_boleto).to eql('1-9 / 0000061900-0')
    boleto_novo.conta_corrente = '619898'
    expect(boleto_novo.agencia_conta_boleto).to eql('1-9 / 0000619898-8')
  end

  describe 'Busca logotipo do banco' do
    it_behaves_like 'busca_logotipo'
  end

  it 'Gerar boleto nos formatos válidos com método to_' do
    valid_attributes[:valor] = 2952.95
    valid_attributes[:data_documento] = Date.parse('2009-04-30')
    valid_attributes[:data_vencimento] = Date.parse('2009-04-30')
    valid_attributes[:numero_documento] = '15234'
    valid_attributes[:conta_corrente] = '0403005'
    valid_attributes[:agencia] = '1172'
    boleto_novo = described_class.new(valid_attributes)

    %w(pdf jpg tif png).each do |format|
      file_body = boleto_novo.send("to_#{format}".to_sym)
      tmp_file = Tempfile.new(['foobar.', format])
      tmp_file.puts file_body
      tmp_file.close
      expect(File.exist?(tmp_file.path)).to be_truthy
      expect(File.stat(tmp_file.path).zero?).to be_falsey
      expect(File.delete(tmp_file.path)).to be(1)
      expect(File.exist?(tmp_file.path)).to be_falsey
    end
  end

  it 'Gerar boleto nos formatos válidos' do
    valid_attributes[:valor] = 2952.95
    valid_attributes[:data_documento] = Date.parse('2009-04-30')
    valid_attributes[:data_vencimento] = Date.parse('2009-04-30')
    valid_attributes[:numero_documento] = '15234'
    valid_attributes[:conta_corrente] = '0403005'
    valid_attributes[:agencia] = '1172'
    boleto_novo = described_class.new(valid_attributes)

    %w(pdf jpg tif png).each do |format|
      file_body = boleto_novo.to(format)
      tmp_file = Tempfile.new(['foobar.', format])
      tmp_file.puts file_body
      tmp_file.close
      expect(File.exist?(tmp_file.path)).to be_truthy
      expect(File.stat(tmp_file.path).zero?).to be_falsey
      expect(File.delete(tmp_file.path)).to be(1)
      expect(File.exist?(tmp_file.path)).to be_falsey
    end
  end

  describe '#agencia_dv' do
    it { expect(described_class.new.agencia_dv).to eq(9) }
  end

  describe '#conta_corrente_dv' do
    it { expect(described_class.new(conta_corrente: '0325620').conta_corrente_dv).to eq(0) }
    it { expect(described_class.new(conta_corrente: '0284025').conta_corrente_dv).to eq(1) }
    it { expect(described_class.new(conta_corrente: '0238069').conta_corrente_dv).to eq(2) }
    it { expect(described_class.new(conta_corrente: '0135323').conta_corrente_dv).to eq(3) }
    it { expect(described_class.new(conta_corrente: '0010667').conta_corrente_dv).to eq(4) }
    it { expect(described_class.new(conta_corrente: '0420571').conta_corrente_dv).to eq(5) }
    it { expect(described_class.new(conta_corrente: '0510701').conta_corrente_dv).to eq(6) }
    it { expect(described_class.new(conta_corrente: '0420536').conta_corrente_dv).to eq(7) }
    it { expect(described_class.new(conta_corrente: '0012500').conta_corrente_dv).to eq(8) }
    it { expect(described_class.new(conta_corrente: '0010673').conta_corrente_dv).to eq(9) }
    it { expect(described_class.new(conta_corrente: '0019669').conta_corrente_dv).to eq('P') }
    it { expect(described_class.new(conta_corrente: '0301357').conta_corrente_dv).to eq('P') }
  end
end
