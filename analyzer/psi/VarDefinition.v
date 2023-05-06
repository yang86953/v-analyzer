module psi

import analyzer.psi.types

pub struct VarDefinition {
	PsiElementImpl
}

fn (n &VarDefinition) identifier() ?PsiElement {
	return n.find_child_by_type(.identifier)
}

fn (n &VarDefinition) name() string {
	if id := n.identifier() {
		return id.get_text()
	}

	return ''
}

fn (n &VarDefinition) expr() {}

fn (n &VarDefinition) get_type() types.Type {
	if parent := n.parent_nth(2) {
		if parent is VarDeclaration {
			if init := parent.initializer_of(n) {
				return init.get_type()
			}
		}
	}

	return types.new_unknown_type()
}