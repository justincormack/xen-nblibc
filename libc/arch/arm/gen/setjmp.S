/*	$NetBSD: setjmp.S,v 1.14 2013/04/19 13:45:45 matt Exp $	*/

/*
 * Copyright (c) 1997 Mark Brinicombe
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by Mark Brinicombe
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#if !defined(__SOFTFP__) && !defined(__VFP_FP__) && !defined(__ARM_PCS)
#error FPA is not supported anymore
#endif

#ifdef __ARM_EABI__
	.fpu	vfp
#endif

#include <machine/asm.h>
#include <machine/setjmp.h>

/*
 * C library -- setjmp, longjmp
 *
 *	longjmp(a,v)
 * will generate a "return(v)" from the last call to
 *	setjmp(a)
 * by restoring registers from the stack.
 * The previous signal state is restored.
 */

ENTRY(__setjmp14)
	/* Get the signal mask. */
	stmfd	sp!, {r0-r2, r14}
	add	r2, r0, #(_JB_SIGMASK * 4)
	mov	r1, #0x00000000
	mov	r0, #0x00000000
	bl	PIC_SYM(_C_LABEL(__sigprocmask14), PLT)
	ldmfd	sp!, {r0-r2, r14}

	ldr	r1, .Lsetjmp_magic

#ifdef __ARM_EABI__
	ldr	r2, .Lfpu_present
#ifdef PIC
	GOT_INIT(r3, .Lsetjmp_got, .Lsetjmp_gotinit)
	ldr	r2, [r2, r3]
#else
	ldr	r2, [r2]
#endif
	teq	r2, #0		/* do we have a FPU? */
	beq	1f		/*   no, don't save VFP registers */

	orr	r1, r1, #(_JB_MAGIC_SETJMP ^ _JB_MAGIC_SETJMP_VFP)
				/* change magic to VFP magic */
	add	r2, r0, #(_JB_REG_D8 * 4)
	vstmia	r2, {d8-d15}
	vmrs	r2, fpscr
	str	r2, [r0, #(_JB_REG_FPSCR * 4)]
1:
#endif /* __ARM_EABI__ */

	str	r1, [r0]		/* store magic */

	/* Store integer registers */
	add	r0, r0, #(_JB_REG_R4 * 4)
        stmia	r0, {r4-r14}
        mov	r0, #0x00000000
        RET

.Lsetjmp_magic:
	.word	_JB_MAGIC_SETJMP
#ifdef __ARM_EABI__
	GOT_INITSYM(.Lsetjmp_got, .Lsetjmp_gotinit)
.Lfpu_present:
	.word	PIC_SYM(_libc_arm_fpu_present, GOTOFF)
#endif /* __ARM_EABI__ */

ENTRY(__longjmp14)
	ldr	r2, [r0]
	ldr	ip, .Lsetjmp_magic
	bic	r3, r2, #(_JB_MAGIC_SETJMP ^ _JB_MAGIC_SETJMP_VFP)
	teq	r3, ip
	bne	.Lbotch

	/* Restore the signal mask. */
	stmfd	sp!, {r0-r2, r14}
	mov	r2, #0x00000000
	add	r1, r0, #(_JB_SIGMASK * 4)
	mov	r0, #3				/* SIG_SETMASK */
	bl	PIC_SYM(_C_LABEL(__sigprocmask14), PLT)
	ldmfd	sp!, {r0-r2, r14}

#ifdef __ARM_EABI__
	tst	r2, #(_JB_MAGIC_SETJMP ^ _JB_MAGIC_SETJMP_VFP)
						/* is this a VFP magic? */
	beq	1f				/*   no, don't restore VFP */
	add	ip, r0, #(_JB_REG_D8 * 4)
	vldmia	ip, {d8-d15}
	ldr	ip, [r0, #(_JB_REG_FPSCR * 4)]
	vmsr	fpscr, ip
1:
#endif /* __ARM_EABI__ */

	add	r0, r0, #(_JB_REG_R4 * 4)
	/* Restore integer registers */
        ldmia	r0, {r4-r14}

	/* Validate sp and r14 */
	teq	sp, #0
	teqne	r14, #0
	beq	.Lbotch

	/* Set return value */
	movs	r0, r1
	moveq	r0, #0x00000001
	RET

	/* validation failed, die die die. */
.Lbotch:
	bl	PIC_SYM(_C_LABEL(longjmperror), PLT)
	bl	PIC_SYM(_C_LABEL(abort), PLT)
	b	. - 8		/* Cannot get here */
