/*
 * \brief  Fiasco.OC-specific part of the CPU session interface
 * \author Stefan Kalkowski
 * \author Norman Feske
 * \date   2011-04-14
 */

/*
 * Copyright (C) 2011-2017 Genode Labs GmbH
 *
 * This file is part of the Genode OS framework, which is distributed
 * under the terms of the GNU Affero General Public License version 3.
 */

#ifndef _INCLUDE__FOC_NATIVE_CPU__FOC_NATIVE_CPU_H_
#define _INCLUDE__FOC_NATIVE_CPU__FOC_NATIVE_CPU_H_

#include <base/rpc.h>
#include <cpu_session/cpu_session.h>
#include <foc/thread_state.h>

namespace Genode { struct Foc_native_cpu; }


struct Genode::Foc_native_cpu : Cpu_session::Native_cpu
{
	virtual Native_capability native_cap(Thread_capability) = 0;
	virtual Foc_thread_state thread_state(Thread_capability) = 0;
	// START Modification for Checkpoint/Restore (rtcr)
	virtual void install(Native_capability, addr_t) = 0;
	virtual addr_t cap_map_info() = 0;
	virtual void cap_map_info(addr_t) = 0;
	// END Modification for Checkpoint/Restore (rtcr)


	/*********************
	 ** RPC declaration **
	 *********************/

	GENODE_RPC(Rpc_native_cap, Native_capability, native_cap, Thread_capability);
	GENODE_RPC(Rpc_thread_state, Foc_thread_state, thread_state, Thread_capability);
	// START Modification for Checkpoint/Restore (rtcr)
	GENODE_RPC(Rpc_install, void, install, Native_capability, addr_t);
	GENODE_RPC(Rpc_get_cap_map_info, addr_t, cap_map_info);
	GENODE_RPC(Rpc_set_cap_map_info, void, cap_map_info, addr_t);

	GENODE_RPC_INTERFACE(Rpc_native_cap, Rpc_thread_state, Rpc_install, Rpc_get_cap_map_info, Rpc_set_cap_map_info);
};

#endif /* _INCLUDE__FOC_NATIVE_CPU__FOC_NATIVE_CPU_H_ */
