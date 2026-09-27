// RootTabView.swift — casca de navegação por abas (spec seção 10/16).
//
// Barra inferior personalizada do design (tela 1): Estante (Home), Quero ler,
// Metas e Configurações, com o botão "+" central de cadastro em destaque (FAB).
// Cada aba tem sua própria pilha de navegação; o "+" abre o formulário de cadastro
// (spec 8.1) de qualquer lugar.

import SwiftUI
import SwiftData

struct RootTabView: View {
    @EnvironmentObject private var store: StoreManager
    @Environment(\.modelContext) private var modelContext
    @State private var aba: Aba = .estante
    @State private var adicionar = false
    // Filtro atual da Biblioteca — controlado aqui para o "Ver tudo" da Home poder
    // abrir a Biblioteca já em "Lendo" (spec 8.4/8.8).
    @State private var bibliotecaFiltro: LibraryFilter = .todos

    enum Aba { case estante, biblioteca, metas, config }

    #if DEBUG
    // Abre uma tela direto na inicialização para capturar screenshots (Paywall do
    // IAP, ou o card de meta batida). Só DEBUG, via env ESTANTE_SHOW_*.
    private enum DebugScreen: Identifiable { case paywall, meta; var id: Int { hashValue } }
    @State private var debugScreen: DebugScreen? = {
        let e = ProcessInfo.processInfo.environment
        if e["ESTANTE_SHOW_PAYWALL"] == "1" { return .paywall }
        if e["ESTANTE_SHOW_META"] == "1" { return .meta }
        return nil
    }()
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
        .fullScreenCover(item: $debugScreen) { tela in
            switch tela {
            case .paywall:
                PaywallView().environmentObject(store)
            case .meta:
                let livros = (try? modelContext.fetch(FetchDescriptor<Livro>())) ?? []
                let metas = (try? modelContext.fetch(FetchDescriptor<Meta>())) ?? []
                if let l = livros.first(where: { $0.status == .lido }),
                   let m = metas.first(where: { $0.tipo_periodo == .mensal }) ?? metas.first {
                    ShareCardView(livro: l, mode: .meta(m)).environmentObject(store)
                }
            }
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
                // Uma linha só: "Configurações" não cabe a 10pt na coluna e quebrava.
                Text(titulo).font(.system(size: 10, weight: selecionado ? .heavy : .semibold))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(selecionado ? Palette.accent : Palette.textMuted)
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
                .background(Palette.accent)
                .clipShape(Circle())
                .shadow(color: Palette.accent.opacity(0.45), radius: 12, y: 8)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .offset(y: -18)
        .accessibilityLabel("Registrar livro")
    }
}
