module lserver

import lsp
import analyzer.psi

pub fn (mut ls LanguageServer) document_symbol(params lsp.DocumentSymbolParams, mut wr ResponseWriter) ![]lsp.DocumentSymbol {
	uri := params.text_document.uri.normalize()
	mut file_symbols := []lsp.DocumentSymbol{}

	elements := stubs_index.get_all_elements_from_file(uri.path())
	for element in elements {
		file_symbols << document_symbol_presentation(element) or { continue }
	}

	return file_symbols
}

fn document_symbol_presentation(element psi.PsiElement) ?lsp.DocumentSymbol {
	full_text_range := element.text_range()
	if element is psi.PsiNamedElement {
		text_range := element.identifier_text_range()
		children := symbol_children(element)
		return lsp.DocumentSymbol{
			name: name_presentation(element)
			detail: detail_presentation(element)
			kind: symbol_kind(element as psi.PsiElement) or { return none }
			range: text_range_to_lsp_range(full_text_range)
			selection_range: text_range_to_lsp_range(text_range)
			children: children
		}
	}

	return none
}

fn symbol_kind(element psi.PsiElement) ?lsp.SymbolKind {
	match element {
		psi.FunctionOrMethodDeclaration {
			if _ := element.receiver() {
				return .method
			}
			return .function
		}
		psi.StructDeclaration {
			return .struct_
		}
		psi.FieldDeclaration {
			return .field
		}
		psi.EnumDeclaration {
			return .enum_
		}
		psi.EnumFieldDeclaration {
			return .enum_member
		}
		psi.ConstantDefinition {
			return .constant
		}
		psi.TypeAliasDeclaration {
			return .type_parameter
		}
		else {}
	}
	return none
}

fn name_presentation(element psi.PsiNamedElement) string {
	if element is psi.FunctionOrMethodDeclaration {
		if receiver := element.receiver() {
			return receiver.get_text() + ' ' + element.name()
		}
		return element.name()
	}
	return element.name()
}

fn detail_presentation(element psi.PsiNamedElement) string {
	if element is psi.FunctionOrMethodDeclaration {
		if signature := element.signature() {
			return 'fn ' + signature.get_text()
		}
	}
	if element is psi.FieldDeclaration {
		return element.get_type().readable_name()
	}
	return ''
}

fn symbol_children(element psi.PsiNamedElement) []lsp.DocumentSymbol {
	mut children := []psi.PsiElement{}
	if element is psi.StructDeclaration {
		children << element.fields()
	} else if element is psi.EnumDeclaration {
		children << element.fields()
	}

	mut symbols := []lsp.DocumentSymbol{cap: children.len}
	for child in children {
		symbols << document_symbol_presentation(child) or { continue }
	}
	return symbols
}