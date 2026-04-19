import SwiftUI
import UIKit

/// Entry screen for the Development Profile PDF. The parent picks a period,
/// optionally adds a note, previews the layout, and taps Export. On export
/// we render the SwiftUI template to a single-page PDF via `ImageRenderer`
/// + `CGContext(url:mediaBox:)` and hand the file URL to a share sheet.
struct DevelopmentProfileExportView: View {
    @StateObject private var viewModel: DevelopmentProfileViewModel
    @State private var exportedFile: ExportedFile?
    @State private var isExporting = false
    @State private var errorMessage: String?

    /// Local Identifiable wrapper so we can drive `.sheet(item:)` off the
    /// generated URL without polluting Foundation.URL with a global
    /// Identifiable conformance.
    private struct ExportedFile: Identifiable {
        let url: URL
        var id: String { url.absoluteString }
    }

    init(child: ChildSummary) {
        _viewModel = StateObject(wrappedValue: DevelopmentProfileViewModel(child: child))
    }

    var body: some View {
        Form {
            Section("Period") {
                Picker("Time range", selection: $viewModel.period) {
                    ForEach(DevelopmentProfileViewModel.Period.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)

                LabeledContent("Sessions") { Text("\(viewModel.totalSessions)").font(.body.bold()) }
                LabeledContent("Training time") { Text(viewModel.totalHoursFormatted).font(.body.bold()) }
                LabeledContent("Current streak") { Text("\(viewModel.currentStreak) days").font(.body.bold()) }
                LabeledContent("Avg RPE") { Text(viewModel.avgEffortLabel).font(.body.bold()) }
            }

            Section {
                TextField("Add a note for the report (optional)", text: $viewModel.parentNote, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Parent's Note")
            } footer: {
                Text("Shown at the bottom of the PDF. Useful for coaches or grandparents.")
            }

            Section {
                Button {
                    Task { await exportPDF() }
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView()
                        } else {
                            Image(systemName: "doc.richtext.fill")
                        }
                        Text(isExporting ? "Generating…" : "Export PDF")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                }
                .disabled(isExporting || viewModel.isLoading)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color.dsError)
                }
            }
        }
        .navigationTitle("Development Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(item: $exportedFile) { file in
            ShareSheet(items: [file.url])
        }
    }

    // MARK: - PDF generation

    @MainActor
    private func exportPDF() async {
        isExporting = true
        errorMessage = nil
        defer { isExporting = false }

        // Render SwiftUI → PDF using ImageRenderer. iOS 16+ API.
        let content = DevelopmentProfileReportView(viewModel: viewModel)
            .frame(
                width: DevelopmentProfileReportView.pageSize.width,
                height: DevelopmentProfileReportView.pageSize.height
            )
        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(DevelopmentProfileReportView.pageSize)

        let filename = "DevelopmentProfile-\(viewModel.childName)-\(Self.filenameFormatter.string(from: Date())).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        renderer.render { size, context in
            var mediaBox = CGRect(origin: .zero, size: DevelopmentProfileReportView.pageSize)
            guard let pdf = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else { return }
            pdf.beginPDFPage(nil)
            // ImageRenderer's content size may differ slightly from the
            // template's explicit frame (SwiftUI layout padding). Scale to
            // fit the mediaBox cleanly so nothing clips.
            let scaleX = DevelopmentProfileReportView.pageSize.width / size.width
            let scaleY = DevelopmentProfileReportView.pageSize.height / size.height
            let scale = min(scaleX, scaleY)
            pdf.scaleBy(x: scale, y: scale)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }

        if FileManager.default.fileExists(atPath: url.path) {
            exportedFile = ExportedFile(url: url)
        } else {
            errorMessage = "Couldn't generate the PDF. Please try again."
        }
    }

    private static let filenameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

/// Thin UIKit wrapper over UIActivityViewController for save/share the PDF.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
