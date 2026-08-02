// RootTabView.swift — casca de navegação por abas (spec seção 10/16).
//
// Barra inferior personalizada do design (tela 1): Estante (Home), Quero ler,
// Metas e Configurações, com o botão "+" central de cadastro em destaque (FAB).
// Cada aba tem sua própria pilha de navegação; o "+" abre o formulário de cadastro
// (spec 8.1) de qualquer lugar.

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var store: StoreManager
    @State private var aba: Aba = .estante
    @State private var adicionar = false
    // Filtro atual da Biblioteca — controlado aqui para o "Ver tudo" da Home poder
    // abrir a Biblioteca já em "Lendo" (spec 8.4/8.8).
    @State private var bibliotecaFiltro: LibraryFilter = .todos

    enum Aba { case estante, biblioteca, metas, config }

    #if DEBUG
    // Abre o Paywall direto na inicialização quando ESTANTE_SHOW_PAYWALL=1 — usado
    // só para capturar a screenshot de review do IAP (App Store Connect). Só DEBUG.
    @State private var debugPaywall = ProcessInfo.processInfo.environment["ESTANTE_SHOW_PAYWALL"] == "1"
    #endif

    var body: some View {
        ZStack(alignment: .bottom) {
            conteudo
            barra
            fab
        }
        .sheet(isPresented: $adicionar) {
            BookFormView().environmentObject(store)
        }
        #if DEBUG
        .fullScreenCover(isPresented: $debugPaywall) {
            PaywallView().environmentObject(store)
        }
        #endif
    }

    @ViewBuilder private var conteudo: some View {
        switch aba {
        case .estante:
            HomeView(onVerTudoLendo: {
                bibliotecaFiltro = .lendo
                aba = .biblioteca
            }).environmentObject(store)
        case .biblioteca:
            BibliotecaView(filtro: $bibliotecaFiltro).environmentObject(store)
        case .metas: GoalsView()
        case .config: SettingsView().environmentObject(store)
        }
    }

    // Barra inferior translúcida com os 4 itens e um vão central para o FAB (spec 16).
    private var barra: some View {
        HStack(alignment: .top) {
            item(.estante, "Estante", "house.fill")
            item(.biblioteca, "Biblioteca", "books.vertical.fill")
            Spacer().frame(width: 56)
            item(.metas, "Metas", "target")
            item(.config, "Configurações", "gearshape.fill")
        }
        .padding(.horizontal, 26)
        .padding(.top, 12)
        .background(
            Palette.screen.opacity(0.86)
                .background(.ultraThinMaterial)
                .overlay(Rectangle().fill(Palette.hairline).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private func item(_ destino: Aba, _ titulo: String, _ icone: String) -> some View {
        let selecionado = aba == destino
        return Button { aba = destino } label: {
            VStack(spacing: 3) {
                Image(systemName: icone).font(.system(size: 18))
                Text(titulo).font(.system(size: 10, weight: selecionado ? .heavy : .semibold))
            }
            .foregroundStyle(selecionado ? Palette.coral : Palette.textMuted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selecionado ? .isSelected : [])
    }

    // Botão "+" central de cadastro (spec 8.1/16).
    private var fab: some View {
        Button { adicionar = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(Palette.coral)
                .clipShape(Circle())
                .shadow(color: Palette.coral.opacity(0.45), radius: 12, y: 8)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .offset(y: -18)
        .accessibilityLabel("Registrar livro")
    }
}
