# -*- encoding: utf-8 -*-
#
module Brcobranca
  module Boleto
    class Inter < Base # Banco INTER (Antigo Intermedium)
      validates_length_of :numero_documento, maximum: 7, message: 'deve ser menor ou igual a 7 dígitos.'
      validates_length_of :conta_corrente, maximum: 10, message: 'deve ser menor ou igual a 10 dígitos.'

      # Nova instancia do Bradesco
      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos = {})
        campos = { carteira: '12' }.merge!(campos)

        campos[:local_pagamento] = 'PAGÁVEL EM QUALQUER BANCO ATÉ O VENCIMENTO'

        super(campos)
      end

      # Codigo do banco emissor (3 dígitos sempre)
      #
      # @return [String] 3 caracteres numéricos.
      def banco
        '077'
      end

      def agencia
        '1'
      end

      def especie_documento
        'OU'
      end

      def aceite
        'NAO'
      end

      def produto
        '000'
      end

      def sistema
        '10'
      end

      # Conta
      #
      # @return [String] 10 caracteres numéricos.
      def conta_corrente=(valor)
        @conta_corrente = valor.to_s[0..9].rjust(10, '0') if valor
      end

      # Carteira
      #
      # @return [String] 2 caracteres numéricos.
      def carteira=(valor)
        @carteira = valor.to_s.rjust(2, '0') if valor
      end

      # Número seqüencial utilizado para identificar o boleto.
      # @return [String] 7 caracteres numéricos.
      def numero_documento=(valor)
        @numero_documento = valor.to_s.rjust(7, '0') if valor
      end

      # Nosso número para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.nosso_numero_boleto #=> ""06/00000004042-8"
      def nosso_numero_boleto
        "#{carteira}/#{numero_documento}-#{nosso_numero_dv}"
      end

      # Dígito verificador da agência
      # @return [Integer] 1 caracteres numéricos.
      def agencia_dv
        agencia.modulo11(
          multiplicador: [2, 3, 4, 5],
          mapeamento: { 10 => 'P', 11 => 0 }
        ) { |total| 11 - (total % 11) }
      end

      # Dígito verificador do nosso número
      # @return [Integer] 1 caracteres numéricos.
      def nosso_numero_dv
        "#{carteira}#{numero_documento}".modulo11(
          multiplicador: [2, 3, 4, 5, 6, 7],
          mapeamento: { 10 => 'P', 11 => 0 }
        ) { |total| 11 - (total % 11) }
      end

      # Dígito verificador da conta corrente
      # @return [Integer] 1 caracteres numéricos.
      def conta_corrente_dv
        conta_corrente.modulo11(
          multiplicador: [2, 3, 4, 5, 6, 7],
          mapeamento: { 10 => 'P', 11 => 0 }
        ) { |total| 11 - (total % 11) }
      end

      # Agência + conta corrente do cliente para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.agencia_conta_boleto #=> "0548-7 / 00001448-6"
      def agencia_conta_boleto
        "#{agencia}-#{agencia_dv} / #{conta_corrente}-#{conta_corrente_dv}"
      end

      # Segunda parte do código de barras.
      #
      # Posição | Tamanho | Conteúdo<br/>
      # 20 a 23 | 4 |  Agência Cedente (Sem o digito verificador, completar com zeros a esquerda quando  necessário)<br/>
      # 24 a 25 | 2 |  Carteira<br/>
      # 26 a 36 | 11 |  Número do Nosso Número(Sem o digito verificador)<br/>
      # 37 a 43 | 7 |  Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necessário)<br/>
      # 44 a 44 | 1 |  Zero<br/>
      #
      # @return [String] 25 caracteres numéricos.
      def codigo_barras_segunda_parte
        "#{agencia}#{produto}#{carteira}#{sistema}#{numero_documento}#{conta_corrente}"
      end
    end
  end
end
