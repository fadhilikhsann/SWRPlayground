//
//  TableViewState.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 27/09/26.
//

enum TableViewState<TASK: Equatable, VALUE: Equatable>: Equatable {
	case start
	case runningTask(TASK)
	case resultTask(VALUE, task: TASK)
	case endTask
	case errorMessage(String)
}
